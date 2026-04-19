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

  # Get the public IP addresses of the EC2 instances

  aws ec2 describe-instances --instance-ids ...$ec2_instance_ids | from json | get Reservations | get Instances | each {|i| select PrivateIpAddress InstanceId } | flatten
}


if ((sys host | get name) == "Windows") {

  # ---------------------------------------------------------------------------
  # Aliases
  # ---------------------------------------------------------------------------

  # Open files/folders in Explorer (mirrors `open` on macOS)
  alias open = explorer.exe

  # Clipboard helpers that match the macOS pbcopy/pbpaste names
  alias pbcopy  = clip.exe
  def pbpaste [] {
    powershell.exe -NoProfile -Command "Get-Clipboard"
  }

  # Use the Windows hosts file shortcut people usually forget exists
  alias hosts = notepad.exe C:\Windows\System32\drivers\etc\hosts

  # ---------------------------------------------------------------------------
  # WezTerm workspace launcher
  # ---------------------------------------------------------------------------

  const WEZTERM_WSL_DOMAIN = "WSL:NixOS"

  # Spawn a tab in the WSL:NixOS domain and return its pane-id
  def wez-spawn [
    cwd: string       # Path inside WSL (\\wsl.localhost\nixos\...)
    --title: string   # Optional tab title
  ] {
    let pane = (wezterm.exe cli spawn --domain-name $WEZTERM_WSL_DOMAIN --cwd $cwd)
    if not ($title | is-empty) {
      wezterm.exe cli set-tab-title --pane-id $pane $title
    }
    $pane
  }

  # Send a command to a pane and press Enter
  def wez-send [pane: string, command: string] {
    wezterm.exe cli send-text --pane-id $pane --no-paste $"($command)\r\n"
  }

  # ---------------------------------------------------------------------------
  # good_morning — open project tabs in WezTerm (Windows-side only)
  # ---------------------------------------------------------------------------
  def good_morning [] {
    let win_user = ($env.USERNAME | str trim)
    let wsl_home = $"\\\\wsl.localhost\\nixos\\home\\($win_user)"
    let tidal_wave = (wez-spawn $"($wsl_home)\\dev\\tidal\\tidal-wave" --title "Tidal Wave🌊")
    wez-send $tidal_wave "tidal-aws mmp"
    let mmp = (wez-spawn $"($wsl_home)\\dev\\tidal\\application-inventory" --title "MMP ♦️")
  }

}
