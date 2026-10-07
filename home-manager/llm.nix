{ config, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;

  platformNote =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "## Platform\n\nThis machine runs macOS."
    else
      "## Platform\n\nThis machine runs WSL2 on Windows.";

  # The Firefox derivation lays itself out differently per platform: Linux gets
  # `bin/firefox`, while Darwin ships only an .app bundle (no `bin/` at all), so
  # the executable has to be reached through Contents/MacOS.
  firefoxBinary =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${pkgs.firefox}/Applications/Firefox.app/Contents/MacOS/firefox"
    else
      "${pkgs.firefox}/bin/firefox";

  agentsMdText = builtins.readFile ./config/AGENTS.md + "\n\n" + platformNote + "\n";
  antigravityAgentsMdText = agentsMdText + "\n## Default Shell\n\nUse `zsh` as the default shell when generating user shell scripts.\n";
  coordinatorPrompt = builtins.readFile ./config/coordinator_agent.md;

  # Define common MCP servers here that you want to share across multiple agents
  sharedMcpServers = {
    nixos = {
      command = "nix";
      args = [ "run" "github:utensils/mcp-nixos" "--" ];
    };
    github = {
      command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
      args = [ "stdio" ];
    };
    postgres = {
      command = "podman";
      args = [
        "run"
        "-i"
        "--rm"
        "--network=host"
        "-e"
        "DATABASE_URI"
        "crystaldba/postgres-mcp"
        "--access-mode=restricted"
      ];
    };
    # Runs as a local embedded (persistent) client inside the container instead
    # of talking to a separate Chroma HTTP server, so there's no server to stand
    # up and no --network=host portability gap between Darwin and NixOS/WSL: a
    # bind-mounted data dir is all it needs, and podman machine on Darwin shares
    # the home directory into the VM by default.
    chroma = {
      command = "podman";
      args = [
        "run"
        "-i"
        "--rm"
        "-v"
        "${home}/.local/share/chroma:/data"
        "ghcr.io/chroma-core/chroma-mcp:latest"
        "chroma-mcp"
        "--client-type"
        "persistent"
        "--data-dir"
        "/data"
      ];
    };
    firefox-devtools = {
      # On WSL, uses the Nix-installed Linux Firefox rather than the Windows install
      # under /mnt/c: launching the Windows .exe via WSL interop leaves geckodriver's
      # WebDriver BiDi handshake hanging indefinitely.
      command = "${pkgs.firefox-devtools-mcp}/bin/firefox-devtools-mcp";
      args = [ "--firefox-path" firefoxBinary "--headless" "--acceptInsecureCerts" ];
    };
    # Example:
    # sqlite = {
    #   command = "${pkgs.nodejs}/bin/npx";
    #   args = [ "-y" "@modelcontextprotocol/server-sqlite" "--db" "${home}/test.db" ];
    # };
  };

  models = {
    pro = "google/models/gemini-3.1-pro-preview";
    flash = "google/models/gemini-flash-latest";
  };

  # Subset of sharedMcpServers exposed to ECA's coding/planning agents.
  ecaMcpServers = {
    inherit (sharedMcpServers) github nixos postgres firefox-devtools;
  };

  ecaWriteTools = [ "edit_file" "write_file" "move_file" ];

  # Agent roster shared by ECA and agy. The prose in ./config/agents/<name>.md is the
  # single source: ECA appends it to its own classpath prompt (`${classpath:...}` is a
  # substitution, so it composes mid-string), and agy gets it as the body of the Markdown
  # agent definition it discovers at ~/.gemini/config/agents/<name>/agent.md.
  #
  # The two backends are kept deliberately identical: same description, same prose, same
  # capability grant (read tools plus non-destructive shell, never write tools), same
  # MCP access and same model tier. Only the vocabularies differ, since ECA names tools
  # and models differently from agy, so each tier and tool set is mapped per backend.
  agentProse = name: builtins.readFile (./config/agents + "/${name}.md");

  # agy agent frontmatter expects model tiers ("pro", "flash", "flash_lite", "inherit")
  # rather than concrete model IDs. Concrete IDs trigger "Invalid model tier" in
  # ParseModelTier and cause agy to reject the agent definition.
  agyModels = {
    pro = "pro";
    flash = "flash";
  };

  agyAgentTools = [ "view_file" "run_command" ];

  sharedAgents = {
    explore = {
      description = "Broad codebase survey, finding files, and mapping module structure.";
      ecaBasePrompt = "prompts/code_agent.md";
      tier = "flash";
      mcp = true;
    };
    investigate = {
      description = "Deep reasoning about specific questions, debugging, and tracing complex behavior.";
      ecaBasePrompt = "prompts/code_agent.md";
      tier = "pro";
      mcp = true;
    };
    plan = {
      description = "Creating implementation plans, architecture decisions, and multi-step strategies.";
      ecaBasePrompt = "prompts/plan_agent.md";
      tier = "pro";
      mcp = true;
    };
    review = {
      description = "Code review, quality analysis, and finding bugs in existing code.";
      ecaBasePrompt = "prompts/code_agent.md";
      tier = "pro";
      mcp = false;
    };
  };

  ecaAgentPrompt = name: agent:
    "\${classpath:${agent.ecaBasePrompt}}\n\n" + agentProse name;

  ecaAgent = name: agent: {
    inherit (agent) description;
    defaultModel = models.${agent.tier};
    prompts.chat = ecaAgentPrompt name agent;
    disabledTools = ecaWriteTools;
    mcpServers = if agent.mcp then ecaMcpServers else { };
  };

  # builtins.toJSON gives a double-quoted scalar, which is valid YAML for any description.
  agyAgentFile = name: agent: ''
    ---
    name: ${name}
    description: ${builtins.toJSON agent.description}
    model: ${agyModels.${agent.tier}}
    inheritMcp: ${lib.boolToString agent.mcp}
    tools:
    ${lib.concatMapStringsSep "\n" (t: "  - ${t}") agyAgentTools}
    ---

    ${agentProse name}
  '';

  agyAgentsDir = pkgs.linkFarm "agy-agents" (lib.mapAttrsToList
    (name: agent: {
      name = "${name}/agent.md";
      path = pkgs.writeText "agy-agent-${name}.md" (agyAgentFile name agent);
    })
    sharedAgents);

  ecaConfig = {
    "$schema" = "https://eca.dev/config.json";
    providers = {
      openai = {
        url = "https://api.openai.com";
      };
      anthropic = {
        url = "https://api.anthropic.com";
      };
      github-copilot = {
        url = "https://api.githubcopilot.com";
      };
      google = {
        url = "https://generativelanguage.googleapis.com/v1beta/openai";
        key = "\${env:GEMINI_API_KEY}";
      };
      ollama = {
        url = "http://localhost:11434";
      };
    };
    defaultModel = models.pro;
    netrcFile = null;
    hooks = { };
    rules = [
      {
        path = "AGENTS.md";
      }
    ];
    commands = [ ];
    disabledTools = [ ];
    toolCall = {
      approval = {
        byDefault = "ask";
        allow = {
          eca__directory_tree = { };
          eca__read_file = { };
          eca__grep = { };
          eca__preview_file_change = { };
          eca__editor_diagnostics = { };
          eca__task = { };
          eca__spawn_agent = { };
          eca__skill = { };
        };
        ask = { };
        deny = { };
      };
      readFile = {
        maxLines = 2000;
      };
      shellCommand = {
        summaryMaxLength = 30;
      };
    };
    plugins = {
      install = [
        "fp-style"
        "superpowers"
        "security-review"
      ];
    };
    mcpTimeoutSeconds = 60;
    lspTimeoutSeconds = 30;

    agent = {
      coordinator = {
        description = "Lightweight orchestrator and router.";
        defaultModel = models.flash;
        prompts = {
          chat = coordinatorPrompt;
        };
        disabledTools = ecaWriteTools;
        mcpServers = ecaMcpServers;
      };
      code = {
        description = "Writing, editing, or refactoring code.";
        defaultModel = models.flash;
        prompts = {
          chat = "\${classpath:prompts/code_agent.md}";
        };
        disabledTools = [
          "preview_file_change"
        ];
        mcpServers = ecaMcpServers;
      };
      # Shell stays available to every shared agent; plan additionally denies the
      # destructive forms outright. agy has no per-agent equivalent, so there the global
      # permissions.allow list in antigravityConfig is what bounds the same commands.
      plan = ecaAgent "plan" sharedAgents.plan // {
        toolCall = {
          approval = {
            deny = {
              eca__shell_command = {
                argsMatchers = {
                  command = [
                    ".*[12&]?>>?\\s*(?!/dev/null($|\\s))(?!&\\d+($|\\s))\\S+.*"
                    ".*\\|\\s*(tee|dd|xargs).*"
                    ".*\\b(sed|awk|perl)\\s+.*-i.*"
                    ".*\\b(rm|mv|cp|touch|mkdir)\\b.*"
                    ".*git\\s+(add|commit|push).*"
                    ".*npm\\s+install.*"
                    ".*-c\\s+[\"'].*open.*[\"']w[\"'].*"
                    ".*bash.*-c.*[12&]?>>?\\s*(?!/dev/null($|\\s))(?!&\\d+($|\\s))\\S+.*"
                  ];
                };
              };
            };
          };
        };
      };
      explore = ecaAgent "explore" sharedAgents.explore;
      investigate = ecaAgent "investigate" sharedAgents.investigate;
      review = ecaAgent "review" sharedAgents.review;
    };
    defaultAgent = "coordinator";
    welcomeMessage = "Welcome to ECA!\n\nType '/' for commands\n\n";
    autoCompactPercentage = 85;
    index = {
      ignoreFiles = [
        {
          type = "gitignore";
        }
      ];
      repoMap = {
        maxTotalEntries = 300;
        maxEntriesPerDir = 25;
      };
    };
    prompts = {
      chat = "\${classpath:prompts/code_agent.md}";
      chatTitle = "\${classpath:prompts/title.md}";
      compact = "\${classpath:prompts/compact.md}";
      init = "\${classpath:prompts/init.md}";
      completion = "\${classpath:prompts/inline_completion.md}";
      rewrite = "\${classpath:prompts/rewrite.md}";
    };
    completion = {
      model = models.flash;
    };
  };

  # Optional: Also configure Claude Desktop if needed
  claudeConfig = {
    mcpServers = sharedMcpServers;
  };

  # Claude Code (the CLI) never reads the Claude Desktop config; it only looks at
  # ~/.claude.json and per-project .mcp.json, neither of which Nix can own. Bake the
  # shared servers into the binary via --mcp-config instead. Repeated --mcp-config
  # flags merge, so a caller passing its own (e.g. Emacs) keeps these too.
  claudeCodeMcpConfig = pkgs.writeText "claude-code-mcp.json" (builtins.toJSON claudeConfig);

  claude-code-with-mcp = pkgs.symlinkJoin {
    name = "claude-code-with-mcp";
    paths = [ pkgs.claude-code ];
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude --add-flags "--mcp-config=${claudeCodeMcpConfig}"
    '';
    meta.mainProgram = "claude";
  };

  claude-agent-acp = pkgs.claude-agent-acp.override {
    claude-code = claude-code-with-mcp;
  };

  geminiConfig = {
    experimental = {
      modelSteering = true;
    };
    general = {
      enableNotifications = true;
    };
    mcpServers = sharedMcpServers;
    security = {
      auth = {
        selectedType = "oauth-personal";
      };
    };
  };

  copilotConfig = {
    mcpServers = lib.mapAttrs
      (name: value: value // {
        type = "stdio";
        tools = [ "*" ];
      })
      sharedMcpServers;
  };

  # Read-only git subcommands, auto-approved. Rules are anchored: the subcommand must
  # directly follow `git` (plus optional -C/--no-pager), and the arguments may not
  # contain shell metacharacters, so `git log; rm -rf ~` never matches.
  allowedGitCommands = [
    "blame"
    "cat-file"
    "check-ignore"
    "describe"
    "diff"
    "grep"
    "log"
    "ls-files"
    "ls-tree"
    "merge-base"
    "rev-parse"
    "shortlog"
    "show"
    "show-ref"
    "stash (list|show)"
    "status"
    "worktree list"
  ];

  gitPrefix = "^git (-C [^ ]+ |--no-pager )*";
  gitArgs = "( [^;&|<>$`\\n]*)?$";
  # A bare word (not a flag), for pattern/ref/name arguments.
  gitWord = "[^-;&|<>$`\\n ][^;&|<>$`\\n ]*";

  gitCommandPattern =
    "command(regex:${gitPrefix}(${lib.concatStringsSep "|" allowedGitCommands})${gitArgs})";

  # Subcommands that both read and write. Only their listing forms are allowed: positional
  # words are accepted solely after an explicit list flag, so `git branch foo`, `git tag v1`,
  # `git remote add`, `git reflog expire` and every -d/-D/-m/-f variant still prompt.
  gitListingPatterns = [
    "command(regex:${gitPrefix}branch( (-a|-r|-v|-vv|--all|--remotes|--verbose|--show-current))*( (--list|--contains|--merged|--no-merged)( ${gitWord})*)?$)"
    "command(regex:${gitPrefix}tag( -n[0-9]*)*( (-l|--list|--contains|--points-at|--merged|--no-merged)( ${gitWord})*)?$)"
    "command(regex:${gitPrefix}remote( (-v|--verbose))?( (show|get-url)( -n)?( ${gitWord})*)?$)"
    "command(regex:${gitPrefix}reflog(( (-n [0-9]+|--oneline|--no-color|--date=[a-z-]+))*| show( (-n [0-9]+|--oneline|--no-color|--date=[a-z-]+|${gitWord}))*)$)"
  ];

  agyStatusline = pkgs.writeShellApplication {
    name = "agy-statusline";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./scripts/agy-statusline.sh;
  };

  antigravityConfig = {
    enableTelemetry = false;
    notifications = true;
    enableTerminalSandbox = false;
    trustedWorkspaces = [ ];
    altScreenMode = "always";
    agentMode = "accept-edits";
    colorScheme = "terminal";
    statusLine = {
      type = "command";
      command = "${agyStatusline}/bin/agy-statusline";
      enabled = true;
    };
    permissions = {
      allow = [
        "read_file(*)"
        "command(biome)"
        "command(bundle exec rubocop)"
        "command(cargo check)"
        "command(cargo clippy)"
        "command(cat)"
        "command(find)"
        "command(gh issue list)"
        "command(gh issue view)"
        "command(gh pr diff)"
        "command(gh pr list)"
        "command(gh pr status)"
        "command(gh pr view)"
        "command(gh run list)"
        "command(gh run view)"
        "command(gh search)"
        gitCommandPattern
        "command(grep)"
        "command(head)"
        "command(ls)"
        "command(nix flake)"
        "command(nixpkgs-fmt)"
        "command(npm run)"
        "command(npm test)"
        "command(npx biome)"
        "command(npx oxfmt)"
        "command(npx oxlint)"
        "command(oxfmt)"
        "command(oxlint)"
        "command(rg)"
        "command(rubocop)"
        "command(tail)"
      ] ++ gitListingPatterns;
    };
  };

  # postgres needs a per-project DATABASE_URI, so agy starts it disabled instead of failing on
  # every launch. Enable it with `agy mcp enable postgres` after exporting DATABASE_URI; use
  # host.containers.internal rather than localhost, since the container runs in the podman VM.
  # (agy swaps this symlink for a real file when enabling; the next home-manager switch resets it.)
  # github needs GITHUB_PERSONAL_ACCESS_TOKEN, which isn't present by default,
  # so it starts disabled for the same reason as postgres. chroma is local
  # (embedded persistent client) and needs no credentials, so it stays enabled.
  antigravityMcpConfig = {
    mcpServers = sharedMcpServers // {
      postgres = sharedMcpServers.postgres // { disabled = true; };
      github = sharedMcpServers.github // { disabled = true; };
    };
  };
in
{

  modules.agentic-skills = {
    enable = true;
    # agy reads global skills from ~/.gemini/config/skills, not the legacy Gemini CLI path.
    agents.gemini.path = ".gemini/config/skills";
    skills = {
      # Ruby & Rails
      superpowers-test-driven-development.enable = true;
      ruby.enable = true;
      layered-rails.enable = true;

      # Rust
      domain-cli.enable = true;
      domain-web.enable = true;
      domain-modeling.enable = true;
      m05-type-driven.enable = true;
      rust-router.enable = true;
      m12-lifecycle.enable = true;

      # Frontend
      accelint-react-best-practices.enable = true;
      accelint-ts-documentation.enable = true;
      frontend-design.enable = true;
      typescript-best-practices.enable = true;
      react.enable = true;
      xstate-v5.enable = true;
      state-management.enable = true;

      #IAC
      pulumi-automation-api.enable = true;
      pulumi-component.enable = true;
      pulumi-terraform-to-pulumi.enable = true;
      pulumi-esc.enable = true;
      pulumi-best-practices.enable = true;

      # Engineering Principles
      composition-patterns.enable = true;
      principle-boundary-discipline.enable = true;
      principle-fix-root-causes.enable = true;
      principle-type-system-discipline.enable = true;

      # Quality & Debugging
      debugging-and-error-recovery.enable = true;
      deslop.enable = true;
      systematic-debugging.enable = true;
      thermo-nuclear-code-quality-review.enable = true;
      pocock-code-review.enable = true;
      verification-before-completion.enable = true;

      # Planning & Process
      brainstorming.enable = true;
      doc-coauthoring.enable = true;
      executing-plans.enable = true;
      grilling = {
        enable = true;
        agents = [ "claude" "copilot" ];
      };
      grill-with-docs = {
        enable = true;
        agents = [ "claude" "copilot" ];
      };
      writing-plans.enable = true;
      planning-and-task-breakdown.enable = true;
      writing-for-agents.enable = true;

      # Tooling
      using-git-worktrees.enable = true;
      subagent-driven-development.enable = true;
      using-superpowers.enable = true; # this is the most important skill to enable for all agents, as it allows them to use the Superpowers tool for enhanced capabilities
    };
  };

  home.packages = with pkgs;
    [
      (pkgs.callPackage ./packages/antigravity-cli/package.nix {
        withAcpServer = true;
      })
      (pkgs.writeShellApplication {
        name = "update-antigravity-cli";
        runtimeInputs = [ curl jq ];
        text = ''
          set -euo pipefail
          # Assuming dotfiles are in ~/dotfiles based on current environment
          DOTFILES_DIR="${home}/dotfiles"
          UPDATE_SCRIPT="$DOTFILES_DIR/home-manager/packages/antigravity-cli/update.sh"

          if [ ! -f "$UPDATE_SCRIPT" ]; then
            echo "Error: Could not find update.sh at $UPDATE_SCRIPT"
            echo "Please ensure your dotfiles are located at $DOTFILES_DIR"
            exit 1
          fi

          echo "Running antigravity-cli update script..."
          "$UPDATE_SCRIPT"
        '';
      })
      claude-code-with-mcp
      claude-agent-acp
      github-copilot-cli
      gh
      github-mcp-server
      firefox-devtools-mcp
    ];

  home.file.".config/eca/config.json".text = builtins.toJSON ecaConfig;

  home.file.".gemini/settings.json".text = builtins.toJSON geminiConfig;

  home.file.".gemini/antigravity-cli/settings.json" = {
    force = true;
    text = builtins.toJSON antigravityConfig;
  };

  # agy creates an empty placeholder here on first run, hence force.
  home.file.".gemini/config/mcp_config.json" = {
    force = true;
    text = builtins.toJSON antigravityMcpConfig;
  };

  home.file.".copilot/mcp-config.json".text = builtins.toJSON copilotConfig;

  # On macOS, Claude Desktop config is in a different place
  home.file."Library/Application Support/Claude/claude_desktop_config.json" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = builtins.toJSON claudeConfig;
  };

  # On Linux, it's usually in ~/.config/Claude/claude_desktop_config.json
  home.file.".config/Claude/claude_desktop_config.json" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    text = builtins.toJSON claudeConfig;
  };

  home.file."AGENTS.md".text = agentsMdText;

  home.file.".gemini/config/AGENTS.md".text = antigravityAgentsMdText;

  # Custom subagents, discovered by agy as ~/.gemini/config/agents/<name>/agent.md, generated
  # from sharedAgents. recursive links each file individually, leaving the directory
  # itself writable.
  home.file.".gemini/config/agents" = {
    source = agyAgentsDir;
    recursive = true;
  };

  home.file.".claude/CLAUDE.md".text = agentsMdText;
}
