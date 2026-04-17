{ config, lib, pkgs, ... }:
let
  home = config.home.homeDirectory;

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
      command = "docker";
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
      env = {
        DATABASE_URI = "\${POSTGRES_DATABASE_URI}";
      };
    };
    # Example:
    # sqlite = {
    #   command = "${pkgs.nodejs}/bin/npx";
    #   args = [ "-y" "@modelcontextprotocol/server-sqlite" "--db" "${home}/test.db" ];
    # };
  };

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
        path = "${home}/GEMINI.md";
      }
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

    # Global MCP servers available to all agents
    mcpServers = sharedMcpServers;

    agent = {
      code = {
        defaultModel = "google/models/gemini-flash-latest";
        prompts = {
          chat = "\${classpath:prompts/code_agent.md}";
        };
        disabledTools = [
          "preview_file_change"
        ];
        # If you wanted to specify different/extra servers per agent:
        # mcpServers = sharedMcpServers // { ... };
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
in
{
  home.packages = with pkgs; [
    gemini-cli
    github-copilot-cli
    gh
    github-mcp-server
  ];

  home.file.".config/eca/config.json".text = builtins.toJSON ecaConfig;

  home.file.".gemini/settings.json".text = builtins.toJSON geminiConfig;

  home.file.".copilot/mcp-config.json".text = builtins.toJSON copilotConfig;

  # On macOS, Claude Desktop config is in a different place
  home.file."Library/Application Support/Claude/claude_desktop_config.json" = lib.mkIf pkgs.stdenv.isDarwin {
    text = builtins.toJSON claudeConfig;
  };

  # On Linux, it's usually in ~/.config/Claude/claude_desktop_config.json
  home.file.".config/Claude/claude_desktop_config.json" = lib.mkIf pkgs.stdenv.isLinux {
    text = builtins.toJSON claudeConfig;
  };

  home.file."GEMINI.md" = {
    text = builtins.readFile ./config/GEMINI.md + "\n\n" + builtins.readFile ./config/AGENTS.md;
  };

  home.file."AGENTS.md" = {
    source = ./config/AGENTS.md;
  };
}
