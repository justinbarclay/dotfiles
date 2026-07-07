# TODO: Validate this works

def select_service [cluster] {
  let services = (aws ecs list-services --cluster $cluster | from json | get serviceArns)
  $services | input list "Select ECS Service"
}

# Returns a list of private ip addresses for instances belonging to `service_name` in an AWS `cluster`
#
# If service name is null then the user will be prompted to select one from all available services in `cluster`
def get_service_ip_addresses [cluster: string # ECS Cluster to search through
  service_name?: string # Service name to find associated instance ids
]: nothing  -> list<string> {
  # Get the task ARNs
  mut service = $service_name
  if ($service | is-empty) {
    $service = (select_service $cluster)
  }
  let task_arns = (aws ecs list-tasks --cluster $cluster --service-name $service | from json | get taskArns)

  # Get the container instance ARNs
  let container_instance_arns = (aws ecs describe-tasks --cluster $cluster --tasks ...$task_arns | from json | get tasks | get containerInstanceArn)

  # Get the EC2 instance IDs
  let ec2_instance_ids = (aws ecs describe-container-instances --cluster $cluster --container-instances ...$container_instance_arns | from json | get containerInstances | get ec2InstanceId)

  # Get the private IP addresses of the EC2 instances
  aws ec2 describe-instances --instance-ids ...$ec2_instance_ids | from json | get Reservations | get Instances | each {|i| select PrivateIpAddress InstanceId } | flatten
}

# ---------------------------------------------------------------------------
# WezTerm workspace launcher
# ---------------------------------------------------------------------------

# Spawn a tab and return its pane-id
def wez-spawn [
  cwd: string       # Working directory for the new tab
  --title: string   # Optional tab title
] {
  let is_windows = ((sys host | get name) == "Windows")
  let pane = if $is_windows {
    (^wezterm cli spawn --domain-name "WSL:nixos" --cwd $cwd)
  } else {
    (^wezterm cli spawn --cwd $cwd)
  }
  if not ($title | is-empty) {
    ^wezterm cli set-tab-title --pane-id $pane $title
  }
  $pane
}

# Send a command to a pane and press Enter
def wez-send [pane: string, command: string] {
  ^wezterm cli send-text --pane-id $pane --no-paste $"($command)\n"
}

# ---------------------------------------------------------------------------
# good_morning — open project tabs in WezTerm
# ---------------------------------------------------------------------------
def good_morning [] {
  let project_base = if ((sys host | get name) == "Windows") {
    let win_user = ($env.USERNAME | str trim)
    [$"\\\\wsl.localhost\\nixos\\home\\($win_user)" dev tidal] | path join
  } else {
    [$env.HOME dev tidal] | path join
  }

  let tidal_wave = (wez-spawn ($project_base | path join "tidal-wave") --title "Tidal Wave🌊")
  wez-send $tidal_wave "tidal-aws mmp"
  let mmp = (wez-spawn ($project_base | path join "application-inventory") --title "MMP ♦️")
}
