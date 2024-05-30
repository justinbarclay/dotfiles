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
   def good_morning [] {
       let tidal_wave = (wezterm.exe cli spawn --domain-name WSL:nixos --cwd \\wsl.localhost\nixos\home\justin\dev\tidal\tidal-wave)
       wezterm.exe cli send-text --pane-id $tidal_wave "tidal-aws mmp\r\n" --no-paste
       wezterm.exe cli set-tab-title --pane-id $tidal_wave "Tidal Wave🌊"
       let mmp = (wezterm.exe cli spawn --domain-name WSL:nixos --cwd \\wsl.localhost\nixos\home\justin\dev\tidal\application-inventory)
       wezterm.exe cli set-tab-title --pane-id $tidal_wave "MMP ♦️"
   }
}
