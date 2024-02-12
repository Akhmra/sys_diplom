# Описание облака
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
