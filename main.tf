# This code is compatible with Terraform 4.25.0 and versions that are backwards compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration

provider "google" {
  credentials = file("~/.config/gcloud/application_default_credentials.json")
  project     = "effective-pipe-424209-r1"
  region      = "us-central1"  # Replace with your preferred region
}

resource "google_compute_instance" "puppet-master" {
  boot_disk {
    auto_delete = true
    device_name = "puppet-master"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240614"
      size  = 35
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-medium"

  metadata = {
    ssh-keys = "suyash:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCWCh+RY9C5B7b+RPKQ7n1jh+XlPXTPnq68dV4PPzDMou9qkUWPC/1ab7eEdayZKebaBntYDNWm11RGjnFdbyMRPZEDdfeaJZO8XD9ykKywAdA9bAYDlXi/pUIAxIUDTVj0nFR9hk+PARcaJxwo2O6RPORN+il9eRL5eLD7YMPfwPC7eG0orRWcJuWnLL3mBeRUW30xnNF+Tgm2KCfCM4b9LdrtibqhyAqMYUbVs/1XxLTJhyHZTH3h+03M2BcKf/W2eTEifoJMTzoEUZXxQDS+29oQM9QlgXdpvxgr4cdp7klTkpqCz8RQAaRXegXZk087xAiG61JHxHyzTm3bJjyAViiTNZUk1s7smOeDADLCS2zn+rzTreEeGllijs56DCsPcUBjahHVWLVMbsp4xUaEiPOHjVD9ueHxRP/Yqx3CugR/78e5KCRHoD7T5VSWEgcI3dFkbShMjJnxn/ciI/sP4JB1e1t5zvPK7jmCLkNpwcvvRJ+0GTbOf2gaWSoqP4c= suyash\nroot:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCWCh+RY9C5B7b+RPKQ7n1jh+XlPXTPnq68dV4PPzDMou9qkUWPC/1ab7eEdayZKebaBntYDNWm11RGjnFdbyMRPZEDdfeaJZO8XD9ykKywAdA9bAYDlXi/pUIAxIUDTVj0nFR9hk+PARcaJxwo2O6RPORN+il9eRL5eLD7YMPfwPC7eG0orRWcJuWnLL3mBeRUW30xnNF+Tgm2KCfCM4b9LdrtibqhyAqMYUbVs/1XxLTJhyHZTH3h+03M2BcKf/W2eTEifoJMTzoEUZXxQDS+29oQM9QlgXdpvxgr4cdp7klTkpqCz8RQAaRXegXZk087xAiG61JHxHyzTm3bJjyAViiTNZUk1s7smOeDADLCS2zn+rzTreEeGllijs56DCsPcUBjahHVWLVMbsp4xUaEiPOHjVD9ueHxRP/Yqx3CugR/78e5KCRHoD7T5VSWEgcI3dFkbShMjJnxn/ciI/sP4JB1e1t5zvPK7jmCLkNpwcvvRJ+0GTbOf2gaWSoqP4c= root"
  }

  name = "puppet-master"

  network_interface {
    access_config {
      nat_ip       = "34.122.226.249"
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/effective-pipe-424209-r1/regions/us-central1/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "169032328193-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["http-server", "https-server", "puppet-network"]
  zone = "us-central1-a"
}

# Puppet Agent instances
locals {
  puppet_agents = {
    puppet-agent1 = {
      name          = "puppet-agent1"
      machine_type  = "e2-small"
      disk_size_gb  = 30
      network_tier  = "PREMIUM"
    },
    puppet-agent2 = {
      name          = "puppet-agent2"
      machine_type  = "e2-small"
      disk_size_gb  = 30
      network_tier  = "PREMIUM"
    },
    puppet-agent3 = {
      name          = "puppet-agent3"
      machine_type  = "e2-small"
      disk_size_gb  = 30
      network_tier  = "PREMIUM"
    }
  }
}



resource "google_compute_instance" "puppet-agents" {
  for_each = local.puppet_agents

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = "us-central1-a"

  metadata = {
    ssh-keys = "suyash:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCWCh+RY9C5B7b+RPKQ7n1jh+XlPXTPnq68dV4PPzDMou9qkUWPC/1ab7eEdayZKebaBntYDNWm11RGjnFdbyMRPZEDdfeaJZO8XD9ykKywAdA9bAYDlXi/pUIAxIUDTVj0nFR9hk+PARcaJxwo2O6RPORN+il9eRL5eLD7YMPfwPC7eG0orRWcJuWnLL3mBeRUW30xnNF+Tgm2KCfCM4b9LdrtibqhyAqMYUbVs/1XxLTJhyHZTH3h+03M2BcKf/W2eTEifoJMTzoEUZXxQDS+29oQM9QlgXdpvxgr4cdp7klTkpqCz8RQAaRXegXZk087xAiG61JHxHyzTm3bJjyAViiTNZUk1s7smOeDADLCS2zn+rzTreEeGllijs56DCsPcUBjahHVWLVMbsp4xUaEiPOHjVD9ueHxRP/Yqx3CugR/78e5KCRHoD7T5VSWEgcI3dFkbShMjJnxn/ciI/sP4JB1e1t5zvPK7jmCLkNpwcvvRJ+0GTbOf2gaWSoqP4c= suyash\nroot:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCWCh+RY9C5B7b+RPKQ7n1jh+XlPXTPnq68dV4PPzDMou9qkUWPC/1ab7eEdayZKebaBntYDNWm11RGjnFdbyMRPZEDdfeaJZO8XD9ykKywAdA9bAYDlXi/pUIAxIUDTVj0nFR9hk+PARcaJxwo2O6RPORN+il9eRL5eLD7YMPfwPC7eG0orRWcJuWnLL3mBeRUW30xnNF+Tgm2KCfCM4b9LdrtibqhyAqMYUbVs/1XxLTJhyHZTH3h+03M2BcKf/W2eTEifoJMTzoEUZXxQDS+29oQM9QlgXdpvxgr4cdp7klTkpqCz8RQAaRXegXZk087xAiG61JHxHyzTm3bJjyAViiTNZUk1s7smOeDADLCS2zn+rzTreEeGllijs56DCsPcUBjahHVWLVMbsp4xUaEiPOHjVD9ueHxRP/Yqx3CugR/78e5KCRHoD7T5VSWEgcI3dFkbShMjJnxn/ciI/sP4JB1e1t5zvPK7jmCLkNpwcvvRJ+0GTbOf2gaWSoqP4c= root"
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240614"
      size  = each.value.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork  = "projects/effective-pipe-424209-r1/regions/us-central1/subnetworks/default"
    access_config {
      network_tier = each.value.network_tier
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "169032328193-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  tags = ["http-server", "https-server", "puppet-network"]
}
