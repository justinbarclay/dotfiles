#!/usr/bin/env nu

def base-patterns [] {
    [
        { id: "eval", regex: "(?<![\\.\\'\"\\w])\\b(eval|class_eval|instance_eval|module_eval)\\b(?!\\s*[\\.:=\\'\"])", desc: "Dynamic code execution (eval)", severity: "HIGH" },
        { id: "command_exec", regex: "(?<![\\'\\\":])\\b(system|exec|spawn)\\b(?![\\'\\\":])|IO\\.popen|Open3\\.popen3|%x[\\[({/\\|]|`\\s*[a-zA-Z0-9_/\\.-]+[^`]*`", desc: "Command execution", severity: "HIGH" },
        { id: "obfuscation_b64", regex: "Base64\\.decode64|Zlib::Inflate|unpack\\(['\"]m", desc: "Obfuscation (Base64/Zlib)", severity: "HIGH" },
        { id: "obfuscation_hex", regex: "\\\\x[0-9a-fA-F]{2}", desc: "Hex encoded characters (potential obfuscation)", severity: "MEDIUM" },
        { id: "deserialization", regex: "Marshal\\.load|YAML\\.load\\b", desc: "Unsafe deserialization", severity: "HIGH" },
        { id: "network", regex: "TCPSocket|UDPSocket|Net::HTTP", desc: "Network socket or HTTP usage", severity: "LOW" },
        { id: "dynamic_send", regex: "(?<![\\'\"\\w])\\b(send|public_send)\\b(?:\\s+[\\'\"]|\\s*\\(|\\s*:[a-zA-Z0-9_]+)", desc: "Dynamic method dispatch", severity: "MEDIUM" },
        { id: "method_hijack", regex: "\\b(alias|alias_method|define_method|undef_method|remove_method)\\b", desc: "Method redefinition or aliasing (potential hijacking)", severity: "MEDIUM" },
        { id: "constant_hijack", regex: "\\b(ARGV|ENV|Gem)\\s*=\\s*|\\bconst_set\\b", desc: "Constant hijacking or environment reassignment", severity: "HIGH" },
        { id: "load_path_manipulation", regex: "(\\$LOAD_PATH|\\$:|\\$LOADED_FEATURES)\\b\\s*(\\.|\\+<<|<<|=)", desc: "Load path or loaded features manipulation", severity: "MEDIUM" },
        { id: "io_redirection", regex: "(\\$stdout|\\$stderr|\\$stdin)\\b\\s*=\\s*|(\\$stdout|\\$stderr)\\.reopen\\b", desc: "Standard I/O redirection", severity: "MEDIUM" },
        { id: "env_read", regex: "\\bENV\\b", desc: "Accessing environment variables", severity: "LOW" }
    ]
}

def find-ruby-files [base_dir: path] {
    glob $"($base_dir)/**/*.rb"
    | append (glob $"($base_dir)/**/*.gemspec")
    | append (glob $"($base_dir)/**/Gemfile")
    | append (glob $"($base_dir)/**/Rakefile")
    | uniq
    | where {|p|
        let s = ($p | into string)
        ($s !~ '/\.git/') and ($s !~ '/vendor/') and ($s !~ '/node_modules/')
    }
}

def scan-file [file: path, base_dir: path, patterns: list] {
    try {
        open --raw $file
        | lines
        | enumerate
        | each {|line|
            $patterns | where {|pat|
                $line.item =~ $pat.regex
            } | each {|pat|
                {
                    file: ($file | path relative-to $base_dir | into string),
                    line: ($line.index + 1),
                    severity: $pat.severity,
                    issue: $pat.desc,
                    code: ($line.item | str trim)
                }
            }
        }
        | flatten
    } catch {
        []
    }
}

def parse-watch-classes [watch_classes: string, interactive: bool] {
    let classes_from_flag = (
        if ($watch_classes | is-empty) {
            []
        } else {
            $watch_classes | split row "," | each { str trim } | where { $in != "" }
        }
    )

    let classes_from_prompt = (
        if $interactive {
            let input_classes = (input "Enter class names to watch for (comma-separated): ")
            if ($input_classes | is-empty) {
                []
            } else {
                $input_classes | split row "," | each { str trim } | where { $in != "" }
            }
        } else {
            []
        }
    )

    $classes_from_flag | append $classes_from_prompt | uniq
}

# Scan a directory for suspicious Ruby patterns
def main [
    dir: path = "."                    # The directory to scan (defaults to current directory)
    --json                             # Output findings in JSON format
    --watch-classes (-w): string = ""  # Comma-separated list of classes to watch for
    --watch-severity (-s): string = "MEDIUM" # Severity to assign to watched classes (HIGH, MEDIUM, LOW)
    --interactive (-i)                 # Prompt interactively for classes to watch
    --describe                         # Describe the patterns we scan for and exit
] {
    let base_dir = ($dir | path expand)
    let patterns = (base-patterns)

    if $describe {
        if $json {
            print ($patterns | to json)
        } else {
            print "Ruby Malicious Pattern Scanner - Built-in Patterns:"
            print ($patterns | table)
        }
        return
    }

    let valid_severities = ["HIGH", "MEDIUM", "LOW"]
    if not ($watch_severity in $valid_severities) {
        print $"Error: Invalid severity '($watch_severity)'. Must be one of: ($valid_severities | str join ', ')"
        return
    }

    let all_watched_classes = (parse-watch-classes $watch_classes $interactive)

    let watch_patterns = (
        if not ($all_watched_classes | is-empty) {
            $all_watched_classes | each {|cls|
                {
                    id: $"watch_($cls)",
                    regex: $"\\b($cls)\\b",
                    desc: $"Reference to watched class: ($cls)",
                    severity: $watch_severity
                }
            }
        } else {
            []
        }
    )

    let patterns = ($patterns | append $watch_patterns)

    if not $json {
        print $"Searching for Ruby files in ($base_dir)..."
        if not ($all_watched_classes | is-empty) {
            print $"Watching for classes: ($all_watched_classes | str join ', ') with severity ($watch_severity)"
        }
    }

    let ruby_files = (find-ruby-files $base_dir)

    if ($ruby_files | is-empty) {
        if $json {
            [] | to json
        } else {
            print "No Ruby files found to scan."
        }
        return
    }

    if not $json {
        print $"Scanning ($ruby_files | length) files for suspicious patterns..."
    }

    let results = ($ruby_files | each {|file|
        scan-file $file $base_dir $patterns
    } | flatten)

    if ($results | is-empty) {
        if $json {
            [] | to json
        } else {
            print "Scan complete. No suspicious patterns found."
        }
    } else {
        let sorted_results = (
            $results
            | insert severity_weight {|row|
                match $row.severity {
                    "HIGH" => 1,
                    "MEDIUM" => 2,
                    "LOW" => 3,
                    _ => 4
                }
            }
            | sort-by severity_weight file line
            | reject severity_weight
        )

        if $json {
            $sorted_results | to json
        } else {
            print $"(char nl)Scan complete. Found ($results | length) potential issues:"
            $sorted_results | table
        }
    }
}
