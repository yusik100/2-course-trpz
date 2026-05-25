terraform {
  required_providers {
    virtualbox = {
      source = "shekeriev/virtualbox"
      version = "0.0.4"
    }
  }
}

provider "virtualbox" {
  delay      = 60
  mintimeout = 5
}

resource "virtualbox_vm" "db" {
  count     = 1
  name      = "db-server"
  # Використовуємо локальний файл, який лежить у цій же папці
  image     = "./virtualbox.box" 
  cpus      = var.vm_cpus
  memory    = var.vm_memory
  user_data = file("${path.module}/cloud_init.yml")

  network_adapter {
    type           = "bridged"
    host_interface = "Qualcomm Atheros AR8131 PCI-E Gigabit Ethernet Controller (NDIS 6.30)"
  }
}

resource "virtualbox_vm" "worker" {
  count     = 1
  name      = "worker-server"
  # Використовуємо локальний файл
  image     = "./virtualbox.box"
  cpus      = var.vm_cpus
  memory    = var.vm_memory
  user_data = file("${path.module}/cloud_init.yml")

  network_adapter {
    type           = "bridged"
    host_interface = "Qualcomm Atheros AR8131 PCI-E Gigabit Ethernet Controller (NDIS 6.30)"
  }
}

output "db_ip" {
  value = element(virtualbox_vm.db.*.network_adapter.0.ipv4_address, 1)
}

output "worker_ip" {
  value = element(virtualbox_vm.worker.*.network_adapter.0.ipv4_address, 1)
}