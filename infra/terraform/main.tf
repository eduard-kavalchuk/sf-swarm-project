terraform {
  required_version = "~> 1.3.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.80.0"
    }
  }
}

provider "yandex" {
  token              = var.token
  cloud_id           = var.cloud_id
  folder_id          = var.folder_id
  zone               = "ru-central1-a"
  storage_access_key = var.storage_access_key
  storage_secret_key = var.storage_secret_key
}

resource "yandex_vpc_network" "network" {
  name = "swarm-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

data "yandex_compute_image" "my_image" {
  family = var.instance_family_image
}

resource "yandex_compute_instance" "vm-manager" {
  name     = "sockshop-docker-swarm-manager"
  hostname = "swarm-manager"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.my_image.id
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    serial-port-enable = "1"
    user-data          = file("${path.module}/userconfig.txt")
  }
}

variable "instance_family_image" {
  description = "Instance image"
  type        = string
  default     = "ubuntu-2004-lts"
}

variable "token" {
  description = "Default yandex authorization token"
  type        = string
}

variable "cloud_id" {
  description = "Default clound ID in yandex cloud"
  type        = string
}

variable "folder_id" {
  description = "Default folder ID in yandex cloud"
  type        = string
}

variable "storage_access_key" {
  description = "Static key ID"
  type        = string
}

variable "storage_secret_key" {
  description = "Static key, secret part"
  type        = string
}

variable "service_account_id" {
  description = "Service account ID"
  type        = string
}

output "internal_ip_address_vm" {
  value = yandex_compute_instance.vm-manager.network_interface[0].ip_address
}

output "external_ip_address_vm" {
  value = yandex_compute_instance.vm-manager.network_interface[0].nat_ip_address
}
