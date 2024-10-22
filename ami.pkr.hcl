variable "region" {
  default = "eu-west-1"
}

source "amazon-ebs" "example" {
  ami_name      = "hardened-ami-{{timestamp}}"
  instance_type = "t2.micro"
  region        = var.region
  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      root-device-type     = "ebs"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical (Ubuntu) Owner ID
  }
  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.example"]

  provisioner "shell" {
    inline = [
      # Step 1: Disable unnecessary services (example)
      "if systemctl list-units --full -all | grep -q 'cups.service'; then sudo systemctl disable cups; fi",
      "if systemctl list-units --full -all | grep -q 'bluetooth.service'; then sudo systemctl disable bluetooth; fi",

      
      # Step 2: Apply the latest security patches
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",

      # Step 3: Configure secure SSH settings
      "sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sudo systemctl reload sshd",

      # Step 4: Install Wazuh agent (example for Ubuntu)
      "curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -",
      "echo 'deb https://packages.wazuh.com/4.x/apt/ stable main' | sudo tee /etc/apt/sources.list.d/wazuh.list",
      "sudo apt-get update -y",
      "sudo apt-get install wazuh-agent -y",

      # Configuring Wazuh agent
      "sudo sed -i 's/MANAGER_IP/192.168.1.100/' /var/ossec/etc/ossec.conf", # Replace with your Wazuh Manager IP
      "sudo systemctl enable wazuh-agent",
      "sudo systemctl start wazuh-agent"
    ]
  }
}

