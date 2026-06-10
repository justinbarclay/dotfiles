#!/usr/bin/env nu

# Main command to update agentic skills catalog
def main [
  --catalog-path: string = "~/dotfiles/home-manager/modules/agentic-skills/skills-catalog.json"
  --dbs (-d): any = "all"
] {
  let catalog_expanded = ($catalog_path | path expand)
  let initial_catalog = if ($catalog_expanded | path exists) {
    open $catalog_expanded
  } else {
    { repos: {} }
  }

  print $"Updating skills catalog at ($catalog_expanded)..."

  # Define repositories using standard layouts
  let standard_repos = [
    { key: "anthropics", owner: "anthropics", repo: "skills", skillsPath: "skills" },
    { key: "vercel", owner: "vercel-labs", repo: "agent-skills", skillsPath: "skills" },
    { key: "openai", owner: "openai", repo: "skills", skillsPath: "skills" },
    { key: "addyosmani", owner: "addyosmani", repo: "agent-skills", skillsPath: "skills" },
    { key: "mindrally", owner: "Mindrally", repo: "skills", skillsPath: "skills" },
    { key: "hypergiant", owner: "gohypergiant", repo: "agent-skills", skillsPath: "skills" },
    { key: "cloudflare", owner: "cloudflare", repo: "skills", skillsPath: "skills" },
    { key: "stripe", owner: "stripe", repo: "ai", skillsPath: "skills" },
    { key: "pocock", owner: "mattpocock", repo: "skills", skillsPath: "skills" }
  ]

  let all_db_keys = ["anthropics" "vercel" "openai" "addyosmani" "mindrally" "hypergiant" "cloudflare" "stripe" "pocock" "cursor"]

  let parsed_dbs = if ($dbs | describe) =~ "list" {
    $dbs
  } else if ($dbs | describe) =~ "string" {
    if $dbs == "all" {
      ["all"]
    } else {
      $dbs | split row "," | each { str trim }
    }
  } else {
    ["all"]
  }

  let keys_to_update = if ("all" in $parsed_dbs) {
    $all_db_keys
  } else {
    $parsed_dbs
  }

  let invalid_keys = ($keys_to_update | where { $in not-in $all_db_keys })
  if ($invalid_keys | length) > 0 {
    print $"Error: Invalid database key(s): ($invalid_keys | str join ', '). Valid keys are: ($all_db_keys | str join ', ')"
    return
  }

  mut current_catalog = $initial_catalog

  # Ensure the "repos" key exists as a record
  if not ("repos" in ($current_catalog | columns)) {
    $current_catalog = ($current_catalog | insert repos {})
  }

  mut fetched_repos = {}

  for key in $all_db_keys {
    if ($key in $keys_to_update) {
      if $key == "cursor" {
        print "Fetching Cursor team kit skills..."
        let cursor_data = (fetch-cursor-skills)
        $fetched_repos = ($fetched_repos | insert cursor $cursor_data)
      } else {
        let r = ($standard_repos | where key == $key | first)
        print $"Fetching repo: ($r.owner)/($r.repo)..."
        let repo_data = (fetch-repo-skills $r.owner $r.repo $r.skillsPath)
        $fetched_repos = ($fetched_repos | insert $key $repo_data)
      }
    } else {
      # Preserve from initial catalog if present
      if ("repos" in ($initial_catalog | columns)) and ($key in ($initial_catalog.repos | columns)) {
        let existing_data = ($initial_catalog.repos | get $key)
        let restored_data = (restore-fetched-repo $key $existing_data)
        $fetched_repos = ($fetched_repos | insert $key $restored_data)
      }
    }
  }

  # Gather a flat list of all skills across all fetched repositories
  mut all_skills_list = []
  for repo_key in ($fetched_repos | columns) {
    let repo = ($fetched_repos | get $repo_key)
    for skill_name in ($repo.skills | columns) {
      let skill_data = ($repo.skills | get $skill_name)
      $all_skills_list = ($all_skills_list | append {
        repo_key: $repo_key,
        skill_name: $skill_name,
        original_name: $skill_name,
        description: $skill_data.description,
        path: $skill_data.path
      })
    }
  }

  # Group by skill_name to detect cross-repo name collisions
  let grouped = ($all_skills_list | group-by skill_name)

  mut resolved_skills = []
  for s_name in ($grouped | columns) {
    let list = ($grouped | get $s_name)
    if ($list | length) > 1 {
      # There is a collision! Prefix each with its repo key
      for item in $list {
        let prefixed = $"($item.repo_key)-($item.original_name)"
        $resolved_skills = ($resolved_skills | append ($item | upsert skill_name $prefixed))
      }
    } else {
      $resolved_skills = ($resolved_skills | append ($list | first))
    }
  }

  # Rebuild the final repositories structure with conflict-resolved skill names
  mut final_repos = {}
  for repo_key in ($fetched_repos | columns) {
    let orig_repo = ($fetched_repos | get $repo_key)
    mut repo_skills = {}
    let repo_items = ($resolved_skills | where repo_key == $repo_key)
    for item in $repo_items {
      $repo_skills = ($repo_skills | upsert $item.skill_name {
        name: $item.skill_name,
        description: $item.description,
        path: $item.path
      })
    }
    let updated_repo = ($orig_repo | upsert skills $repo_skills)
    $final_repos = ($final_repos | insert $repo_key $updated_repo)
  }

  $current_catalog = ($current_catalog | upsert repos $final_repos)

  # Clean up any literal "repos.xxx" keys if they got written previously
  let cols = ($current_catalog | columns)
  for col in ["repos.anthropics", "repos.vercel", "repos.openai", "repos.cursor"] {
    if $col in $cols {
      $current_catalog = ($current_catalog | reject $col)
    }
  }

  $current_catalog | save -f $catalog_expanded
  print "Skills catalog successfully updated!"
}

# Helper to restore skills from catalog format to fetched format
def restore-fetched-repo [repo_key: string, repo_data: any] {
  if $repo_key == "cursor" {
    return $repo_data
  }
  let restored_skills = (
    if ($repo_data.skills | is-empty) {
      {}
    } else {
      $repo_data.skills
      | transpose resolved_name data
      | each {|row|
          let orig_name = ($row.data.path | path basename)
          {
            key: $orig_name,
            val: ($row.data | upsert name $orig_name)
          }
        }
      | reduce -f {} {|item, acc| $acc | upsert $item.key $item.val }
    }
  )
  $repo_data | upsert skills $restored_skills
}

# Helper to fetch latest Cursor plugins commit, Nix hash, and parse its skills recursively
def fetch-cursor-skills [] {
  let owner = "cursor"
  let repo = "plugins"

  # 1. Fetch latest main commit SHA
  let commits_url = $"https://api.github.com/repos/($owner)/($repo)/commits/main"
  let rev = (http get -H ["Accept" "application/vnd.github.v3+json"] $commits_url | get sha)

  # 2. Compute Nix hash and store path
  let archive_url = $"https://github.com/($owner)/($repo)/archive/($rev).tar.gz"
  let prefetch = (nix-prefetch-url --unpack --print-path $archive_url | lines)
  let raw_hash = ($prefetch | get 0 | str trim)
  let store_path = ($prefetch | get 1 | str trim)

  let hash = (nix hash convert --hash-algo sha256 --to sri $raw_hash | str trim)

  # 3. Recursively find all SKILL.md files in the Cursor plugins store path
  let skill_files = (glob $"($store_path)/**/SKILL.md")

  mut parsed_skills = []

  for skill_file in $skill_files {
    let skill_dir = ($skill_file | path dirname)
    let skill_name = ($skill_dir | path basename)
    let relative_path = ($skill_dir | path relative-to $store_path | into string)
    let subproject = ($relative_path | split row "/" | first)

    let content = (open -r $skill_file)
    let desc = (parse-skill-description $content)

    $parsed_skills = ($parsed_skills | append {
      name: $skill_name,
      subproject: $subproject,
      description: $desc,
      path: $relative_path
    })
  }

  # Group by skill name to check for internal conflicts
  let grouped = ($parsed_skills | group-by name)

  mut skills = {}

  for skill_name in ($grouped | columns) {
    let list = ($grouped | get $skill_name)
    if ($list | length) > 1 {
      # There is a collision! Prefix each with its subproject name
      for item in $list {
        let prefixed_name = $"($item.subproject)-($skill_name)"
        $skills = ($skills | upsert $prefixed_name {
          name: $prefixed_name,
          description: $item.description,
          path: $item.path
        })
      }
    } else {
      # No collision, insert with standard flat name
      let item = ($list | first)
      $skills = ($skills | upsert $skill_name {
        name: $skill_name,
        description: $item.description,
        path: $item.path
      })
    }
  }

  {
    owner: $owner,
    repo: $repo,
    rev: $rev,
    hash: $hash,
    skillsPath: "",
    skills: $skills
  }
}

# Helper to fetch latest commit, calculate Nix hash, and parse skill definitions recursively
def fetch-repo-skills [owner: string, repo: string, skillsPath: string] {
  # 1. Get the latest main commit SHA via the GitHub API
  let commits_url = $"https://api.github.com/repos/($owner)/($repo)/commits/main"
  let rev = (http get -H ["Accept" "application/vnd.github.v3+json"] $commits_url | get sha)

  # 2. Compute Nix SRI hash and store path via nix-prefetch-url
  let archive_url = $"https://github.com/($owner)/($repo)/archive/($rev).tar.gz"
  let prefetch = (nix-prefetch-url --unpack --print-path $archive_url | lines)
  let raw_hash = ($prefetch | get 0 | str trim)
  let store_path = ($prefetch | get 1 | str trim)

  let hash = (nix hash convert --hash-algo sha256 --to sri $raw_hash | str trim)

  # 3. Read the skills directory directly from the Nix store path
  let local_skills_path = ($store_path | path join $skillsPath)

  # Find all SKILL.md files recursively
  let skill_files = if ($local_skills_path | path exists) {
    glob $"($local_skills_path)/**/SKILL.md"
  } else {
    []
  }

  mut skills = {}

  for skill_file in $skill_files {
    let skill_dir = ($skill_file | path dirname)
    let skill_name = ($skill_dir | path basename)
    let relative_path = ($skill_dir | path relative-to $store_path | into string)

    let content = (open -r $skill_file)
    let desc = (parse-skill-description $content)

    $skills = ($skills | upsert $skill_name {
      name: $skill_name,
      description: $desc,
      path: $relative_path
    })
  }

  {
    owner: $owner,
    repo: $repo,
    rev: $rev,
    hash: $hash,
    skillsPath: $skillsPath,
    skills: $skills
  }
}

# Helper to extract the description line from YAML frontmatter in SKILL.md
def parse-skill-description [md_content: string] {
  let lines = ($md_content | lines)
  let desc_lines = ($lines | where { |l| $l | str starts-with "description:" })
  if ($desc_lines | length) > 0 {
    let desc_line = ($desc_lines | first)
    return ($desc_line | str replace --regex '^description:\s*' "" | str trim -c '"' | str trim -c "'")
  }
  "No description available"
}
