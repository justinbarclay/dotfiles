{ config, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;

  platformNote =
    if pkgs.stdenv.isDarwin then
      "## Platform\n\nThis machine runs macOS."
    else
      "## Platform\n\nThis machine runs WSL2 on Windows.";

  agentsMdText = builtins.readFile ./config/AGENTS.md + "\n\n" + platformNote + "\n";

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
    # Example:
    # sqlite = {
    #   command = "${pkgs.nodejs}/bin/npx";
    #   args = [ "-y" "@modelcontextprotocol/server-sqlite" "--db" "${home}/test.db" ];
    # };
  };

  # Subset of sharedMcpServers exposed to ECA's coding/planning agents.
  ecaMcpServers = lib.filterAttrs (name: _: builtins.elem name [ "github" "nixos" "postgres" ]) sharedMcpServers;

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
    defaultModel = "google/models/gemini-3.1-pro-preview";
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
      code = {
        defaultModel = "google/models/gemini-flash-latest";
        prompts = {
          chat = "\${classpath:prompts/code_agent.md}";
        };
        disabledTools = [
          "preview_file_change"
        ];
        mcpServers = ecaMcpServers;
      };
      plan = {
        defaultModel = "google/models/gemini-pro-latest";
        prompts = {
          chat = "\${classpath:prompts/plan_agent.md}";
        };
        disabledTools = [
          "edit_file"
          "write_file"
          "move_file"
        ];
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
    };
    defaultAgent = "code";
    welcomeMessage = "Welcome to ECA!\n\nType '/' for commands\n\n";
    autoCompactPercentage = 85;
    index = {
      ignoreFiles = [
        {
          type = "gitignore";
        }
      ];
      repoMap = {
        maxTotalEntries = 800;
        maxEntriesPerDir = 50;
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
      model = "google/models/gemini-flash-latest";
    };
  };

  # Optional: Also configure Claude Desktop if needed
  claudeConfig = {
    mcpServers = sharedMcpServers;
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
      brakeman.enable = true;
      lucianghinda-test-driven-development.enable = true;
      rails-guides.enable = true;
      ruby.enable = true;
      sandi-metz-rules.enable = true;

      # Rust
      domain-cli.enable = true;
      domain-web.enable = true;
      m05-type-driven.enable = true;
      rust-router.enable = true;

      # Frontend
      accelint-react-best-practices.enable = true;
      accelint-ts-documentation.enable = true;
      compound.enable = true;
      frontend-design.enable = true;
      typescript-best-practices.enable = true;

      # Engineering Principles
      composition-patterns.enable = true;
      principle-boundary-discipline.enable = true;
      principle-fix-root-causes.enable = true;
      principle-type-system-discipline.enable = true;

      # Quality & Debugging
      debugging-and-error-recovery.enable = true;
      deslop.enable = true;
      systematic-debugging.enable = true;
      thermos-thermo-nuclear-code-quality-review.enable = true;
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

      # Tooling
      using-git-worktrees.enable = true;
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
      claude-code
      github-copilot-cli
      gh
      github-mcp-server
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

  home.file.".gemini/AGENTS.md".text = agentsMdText;

  home.file.".claude/CLAUDE.md".text = agentsMdText;
}
