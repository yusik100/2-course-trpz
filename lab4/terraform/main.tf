terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

resource "virtualbox_vm" "worker" {
  name      = "lab4-worker"
  image     = "https://app.vagrantup.com/ubuntu/boxes/jammy64/versions/20240119.0.0/providers/virtualbox.box"
  cpus      = 1
  memory    = "1.0 gib"
  user_data = file("${path.module}/cloud_init.yml")

  network_adapter {
    type = "nat"
  }

  network_adapter {
    type           = "hostonly"
    host_interface = "VirtualBox Host-Only Ethernet Adapter"
  }
}

resource "virtualbox_vm" "db" {
  name      = "lab4-db"
  image     = "https://app.vagrantup.com/ubuntu/boxes/jammy64/versions/20240119.0.0/providers/virtualbox.box"
  cpus      = 1
  memory    = "1.0 gib"
  user_data = file("${path.module}/cloud_init.yml")

  network_adapter {
    type = "nat"
  }

  network_adapter {
    type           = "hostonly"
    host_interface = "VirtualBox Host-Only Ethernet Adapter"
  }
}

output "worker_ip" {
  value = virtualbox_vm.worker.network_adapter[1].ipv4_address
}

output "db_ip" {
  value = virtualbox_vm.db.network_adapter[1].ipv4_address
}