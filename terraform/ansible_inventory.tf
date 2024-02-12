# hosts.ini
resource "local_file" "ansible-inventory" {
  content  = <<-EOT
    [bastion]
    ${yandex_compute_instance.bastion.network_interface.0.ip_address} public_ip=${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} ansible_user=user
    
    [web_servers]
    ${yandex_compute_instance.webserver-1.network_interface.0.ip_address} ansible_user=user
    ${yandex_compute_instance.webserver-2.network_interface.0.ip_address} ansible_user=user

    [web_server_1]
    ${yandex_compute_instance.webserver-1.network_interface.0.ip_address} ansible_user=user

    [web_server_2]
    ${yandex_compute_instance.webserver-2.network_interface.0.ip_address} ansible_user=user

    [zabbix]
    ${yandex_compute_instance.zabbix-server.network_interface.0.ip_address} public_ip=${yandex_compute_instance.zabbix-server.network_interface.0.nat_ip_address} ansible_user=user

    [zabbix_server]
    ${yandex_compute_instance.zabbix-server.network_interface.0.ip_address} ansible_user=user
    
    [elastic_server]
    ${yandex_compute_instance.elasticsearch.network_interface.0.ip_address} ansible_user=user

    [kibana_server]
    ${yandex_compute_instance.kibana.network_interface.0.ip_address} public_ip=${yandex_compute_instance.kibana.network_interface.0.nat_ip_address} ansible_user=user

    [all:vars]
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -p 22 -W %h:%p -q user@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
    zabbix_ext_ip=${yandex_compute_instance.zabbix-server.network_interface.0.nat_ip_address}
    zabbix_int_ip=${yandex_compute_instance.zabbix-server.network_interface.0.ip_address}

    EOT
  filename = "../ansible/hosts.ini"
}