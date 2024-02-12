#  Дипломная работа по профессии «Системный администратор» SYS-19 Сухин Даниил  

## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/) и отвечать минимальным стандартам безопасности: запрещается выкладывать токен от облака в git. Используйте [инструкцию](https://cloud.yandex.ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials).  

[Полное задание к дипломной работе:](https://github.com/netology-code/sys-diplom/tree/diplom-zabbix)  
---

# Результат
## [Сайт](http://158.160.140.199)
## [Zabbix](http://158.160.127.199) (Логин: Admin | Пароль: zabbix)
## [Elasticsearch](http://51.250.81.187:5601)

# Подготовка к развёртке инфраструктуры

- скачивание последней версии Terraform из [зеркала](https://hashicorp-releases.yandexcloud.net/terraform/) Яндекс.
```
wget https://hashicorp-releases.yandexcloud.net/terraform/1.7.3/terraform_1.7.3_linux_amd64.zip
```
- распковка архива
```
zcat terraform_1.7.3_linux_amd64.zip > terraform
```
- выдача прав на запуск
```
chmod 766 terraform
```
- проверка работоспособности
```
./terraform -v
```
- создание файла конфигурации и выдача прав
```
nano ~/.terraformrc
chmod 644 .terraformrc
```
- вносим данные, указанные в [документации](https://cloud.yandex.ru/ru/docs/tutorials/infrastructure-management/terraform-quickstart#get-credentials)
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```
- в папке, в которой будет запускаться Terraform, нужно создать файл ```main.tf``` с следующим содежанием
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

# Описание доступа и токена
provider "yandex" {
  token     = "OAuth-токен"
  cloud_id  = "ID облака"
  folder_id = "ID папки"
}
```
- там же, создать файл ```meta.yaml```
```
#cloud-config
 users:
  - name: user
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
     - ssh-rsa **********
```
- генерация ключа ssh
```
ssh-keygen
```
- скопировать содержимое ключа ssh-rsa в файл ```meta.yaml```
```
cat ~/.ssh/id_rsa.pub
```
- инициализация Terraform
```
./terraform init
```
![Terraform_init](img/Terraform_init.png)

---

# Развёртка Terraform
После подготовки остальных ```.tf``` конфигов можно начинать развертку из папки Terraform.

- запуск развертки
```
./terraform apply
```
- получаем список IP-адресов (файл ```ansible_inventory.tf``` копирует адреса в файл ```/ansibe/hosts.ini```)

![Terraform_output](./img/Terraform_output.png)

Проверка результата в Yandex Cloud:
- одна сеть bastion-network
- две подсети bastion-internal-segment и bastion-external-segment
- Балансировщик alb-lb с роутером web-servers-router, целевой группой tg-web

![Yandex_cloud_General](./img/Yandex_cloud_general.png)

- 6 виртуальных машин

![Yandex_Cloud_VM](./img/Yandex_cloud_vm.png)

- 10 групп безопасности

![Yandex_Cloud_SG](./img/Yandex_cloud_sg.png)

- ежедневные снимки дисков по расписанию

![Yandex_Cloud_Snapshots](./img/Yandex_cloud_snapshots.png)
---

# Развёртка Ansible
Первым делом, нужно установить Ansible, однако с его установкой и запуском есть ряд не очевидных нюансов.
В данном проекте я использовал не только ```roles``` но ```collections```, однако если на Debian 11 использовать команду
```
apt install ansible
```
тогда он установит старую версию ```10.0.0```. Для использования ```collections``` нужно иметь версию не менее ```11.0.0```.
Так что, я рекомендую внимательно смотреть на версию Ansbile и версии ```collections``` и ```roles``` что бы они были совместимы. Более подробно это описано в официальной [документации](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) Ansible.

- установка Ansible
```
$ UBUNTU_CODENAME=focal
$ wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
$ echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list
$ sudo apt update && sudo apt install ansible
```
- создание папки ```/distribute``` и скачивание ```.deb``` пакетов elasticsearch, filebeat, kibana из [зеркала](https://mirror.yandex.ru/mirrors/elastic/) Яндекс. Версии должны быть одинаковыми и указываться в файле ```/ansible/elk/vars.yml```.
```
mkdir distribute
cd distribute/
wget https://mirror.yandex.ru/mirrors/elastic/7/pool/main/e/elasticsearch/elasticsearch-7.17.14-amd64.deb
wget https://mirror.yandex.ru/mirrors/elastic/7/pool/main/f/filebeat/filebeat-7.17.14-amd64.deb
wget https://mirror.yandex.ru/mirrors/elastic/7/pool/main/k/kibana/kibana-7.17.14-amd64.deb
```
- создание файла ```/ansible/ansible.cfg``` и проверка, что ансибл принял конфиг.
```
ansible --version
```
- пинг хостов и копирование ключа ssh
```
ansible all -m ping
```
![Ansible_Ping](./img/ansible_ping.png)

- запуск первого плейбука, который устанавливает ```roles``` и ```collections```
```
ansible-playbook playbook1.yml
```
![Ansible_PB_1](./img/ansible_pb1.png)

- запуск второго плейбука, который переносит и устанавливает все необходимые приложения, конфиги и ```html``` страницы
```
ansible-playbook playbook2.yml --vault-password-file pass -v
```

![Ansible_PB_2](img/ansible_pb2.png)

---

# Результат
- проверка работы балансировщика

```
curl -v 158.160.140.199:80
```
- либо зайти на сам [балансировщик](http://158.160.140.199)

![Webserver_1](./img/web-server1.png)

![Webserver_2](./img/web-server2.png)

- проверка работы [Zabbix](http://158.160.127.199) и сбора метрик (Логин: Admin | Пароль: zabbix)

![Zabbix_General](./img/Zabbix_general.png)

![Zabbix_Hosts](./img/Zabbix_hosts.png)

- проверка работы Elasticsearch + Kibana, а также отправки Filebeat-ом метрик с веб-серверов

![Elastic_Hosts](./img/Elastic_hosts.png)

![Elastic_Stream](./img/Elastic_stream.png)

