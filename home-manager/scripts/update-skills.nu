#!/usr/bin/env nu

# Main command to update agentic skills catalog
def main [
  --catalog-path: string = "~/dotfiles/home-manager/modules/agentic-skills/skills-catalog.json"
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
    { key: "openai", owner: "openai", repo: "skills", skillsPath: "skills" }
  ]

  mut current_catalog = $initial_catalog
  mut seen_skills = {}

  # Ensure the "repos" key exists as a record
  if not ("repos" in ($current_catalog | columns)) {
    $current_catalog = ($current_catalog | insert repos {})
  }

  for r in $standard_repos {
    print $"Fetching repo: ($r.owner)/($r.repo)..."
    let repo_data = (fetch-repo-skills $r.owner $r.repo $r.skillsPath)
    for skill_name in ($repo_data.skills | columns) {
      if $skill_name in $seen_skills {
        error make {
            msg: $"Skill name collision detected! Skill '($skill_name)' exists in both ($seen_skills | get $skill_name) and ($r.key)."
        }
      }
      $seen_skills = ($seen_skills | insert $skill_name $r.key)
    }
    let updated_repos = ($current_catalog.repos | upsert $r.key $repo_data)
    $current_catalog = ($current_catalog | upsert repos $updated_repos)
  }

  print "Fetching Cursor team kit skills..."
  let cursor_data = (fetch-cursor-skills)
  for skill_name in ($cursor_data.skills | columns) {
    if $skill_name in $seen_skills {
      error make {
          msg: $"Skill name collision detected! Skill '($skill_name)' exists in both ($seen_skills | get $skill_name) and cursor."
      }
    }
    $seen_skills = ($seen_skills | insert $skill_name "cursor")
  }
  let updated_repos = ($current_catalog.repos | upsert cursor $cursor_data)
  $current_catalog = ($current_catalog | upsert repos $updated_repos)

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

# Helper to fetch latest commit, calculate Nix hash, and parse skill definitions
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

  # Find all subdirectories
  let skill_dirs = if ($local_skills_path | path exists) {
    ls $local_skills_path | where type == "dir" | each { |it| $it.name | path basename }
  } else {
    []
  }

  mut skills = {}

  for skill_name in $skill_dirs {
    let skill_file = ($local_skills_path | path join $skill_name "SKILL.md")
    if ($skill_file | path exists) {
      let content = (open -r $skill_file)
      let desc = (parse-skill-description $content)

      $skills = ($skills | upsert $skill_name {
        name: $skill_name,
        description: $desc,
        path: $"($skillsPath)/($skill_name)"
      })
    }
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
