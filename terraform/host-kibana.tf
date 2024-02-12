# Описание Kibana VM
resource "yandex_compute_instance" "kibana" {

  name                      = "kibana"
  hostname                  = "kibana"
  zone                      = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8s17cfki4sd4l6oa59"
      size     = 5
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bastion-external-segment.id
    
    security_group_ids = [ 
                           yandex_vpc_security_group.internal-ssh-sg.id,
                           yandex_vpc_security_group.external-ssh-sg.id,
                           yandex_vpc_security_group.zabbix-sg.id,
                           yandex_vpc_security_group.kibana-sg.id,
                           yandex_vpc_security_group.egress-sg.id
                         ]
                         
    nat        = true
    ip_address = "192.168.50.30"
  }

  metadata = {
    user-data = "${file("./meta.yaml")}"
  }

  scheduling_policy {
    preemptible = false
  }

}