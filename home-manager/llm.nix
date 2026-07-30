{ config, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;

  platformNote =
    if pkgs.stdenv.isDarwin then
      "## Platform\n\nThis machine runs macOS."
    else
      "## Platform\n\nThis machine runs WSL2 on Windows.";

  # The Firefox derivation lays itself out differently per platform: Linux gets
  # `bin/firefox`, while Darwin ships only an .app bundle (no `bin/` at all), so
  # the executable has to be reached through Contents/MacOS.
  firefoxBinary =
    if pkgs.stdenv.isDarwin then
      "${pkgs.firefox}/Applications/Firefox.app/Contents/MacOS/firefox"
    else
      "${pkgs.firefox}/bin/firefox";

  agentsMdText = builtins.readFile ./config/AGENTS.md + "\n\n" + platformNote + "\n";
  antigravityAgentsMdText = agentsMdText + "\n## Default Shell\n\nUse `zsh` as the default shell for all commands.\n";
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
    chroma = {
      command = "podman";
      args = [
        "run"
        "-i"
        "--rm"
        "--network=host"
        "ghcr.io/chroma-core/chroma-mcp:latest"
        "chroma-mcp"
        "--client-type"
        "http"
        "--host"
        "localhost"
        "--port"
        "8000"
        "--ssl"
        "false"
      ];
    };
    firefox-devtools = {
      # On WSL, uses the Nix-installed Linux Firefox rather than the Windows install
      # under /mnt/c: launching the Windows .exe via WSL interop leaves geckodriver's
      # WebDriver BiDi handshake hanging indefinitely.
      command = "${pkgs.firefox-devtools-mcp}/bin/firefox-devtools-mcp";
      args = [ "--firefox-path" firefoxBinary "--headless" ];
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
      plan = {
        description = "Creating implementation plans, architecture decisions, and multi-step strategies.";
        defaultModel = models.pro;
        prompts = {
          chat = "\${classpath:prompts/plan_agent.md}";
        };
        disabledTools = ecaWriteTools;
        mcpServers = ecaMcpServers;
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
      explore = {
        description = "Broad codebase survey, finding files, and mapping module structure.";
        defaultModel = models.flash;
        # Inherits top-level prompts.chat (code_agent.md).
        disabledTools = ecaWriteTools;
        mcpServers = ecaMcpServers;
      };
      investigate = {
        description = "Deep reasoning about specific questions, debugging, and tracing complex behavior.";
        defaultModel = models.pro;
        # Inherits top-level prompts.chat (code_agent.md).
        disabledTools = ecaWriteTools;
        mcpServers = ecaMcpServers;
      };
      review = {
        description = "Code review, quality analysis, and finding bugs in existing code.";
        defaultModel = models.pro;
        # Inherits top-level prompts.chat (code_agent.md).
        disabledTools = ecaWriteTools;
        mcpServers = { };
      };
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

  antigravityConfig = {
    enableTelemetry = false;
    enableNotifications = true;
    enableTerminalSandbox = false;
    trustedWorkspaces = [ ];
    altScreenMode = "always";
    statusLine = {
      enabled = true;
    };
  };

  antigravityMcpConfig = {
    mcpServers = sharedMcpServers;
  };
in
{

  modules.agentic-skills = {
    enable = true;
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
      writing-great-skills.enable = true;

      # Tooling
      using-git-worktrees.enable = true;
      subagent-driven-development.enable = true;
      using-superpowers.enable = true; # this is the most important skill to enable for all agents, as it allows them to use the Superpowers tool for enhanced capabilities
    };
  };

  home.packages = with pkgs;
    [
      (pkgs.callPackage ./packages/antigravity-cli/package.nix { })
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

  home.file.".gemini/antigravity-cli/mcp_config.json".text = builtins.toJSON antigravityMcpConfig;

  home.file.".copilot/mcp-config.json".text = builtins.toJSON copilotConfig;

  # On macOS, Claude Desktop config is in a different place
  home.file."Library/Application Support/Claude/claude_desktop_config.json" = lib.mkIf pkgs.stdenv.isDarwin {
    text = builtins.toJSON claudeConfig;
  };

  # On Linux, it's usually in ~/.config/Claude/claude_desktop_config.json
  home.file.".config/Claude/claude_desktop_config.json" = lib.mkIf pkgs.stdenv.isLinux {
    text = builtins.toJSON claudeConfig;
  };

  home.file."AGENTS.md".text = agentsMdText;

  home.file.".gemini/AGENTS.md".text = antigravityAgentsMdText;

  home.file.".claude/CLAUDE.md".text = agentsMdText;
}
