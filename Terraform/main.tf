terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  subscription_id = var.provider_credentials.subscription_id
  tenant_id       = var.provider_credentials.tenant_id
  client_id       = var.provider_credentials.sp_client_id
  client_secret   = var.provider_credentials.sp_client_secret
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_config.name
  location = var.resource_group_config.location
}


resource "azurerm_postgresql_server" "dbserver" {
  name                         = var.db_server_config.name
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = azurerm_resource_group.resource_group.location
  version                      = "12.0"
  administrator_login          = var.db_server_config.user
  administrator_login_password = var.db_server_config.password

  depends_on = [azurerm_resource_group.resource_group]
}

resource "azurerm_postgresql_database" "db" {
  name                = var.db_config.name
  server_id           = azurerm_postgresql_server.dbserver.id
  sku_name            = "Basic"
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb         = 2
  min_capacity        = 0.5
  zone_redundant      = false
  auto_pause_delay_in_minutes = 60
  depends_on = [azurerm_postgresql_server.dbserver]
}

resource "azurerm_postgresql_firewall_rule" "allow_azure_ips" {
  name                = "AllowAzureServices"
  server_id           = azurerm_postgresql_server.dbserver.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_firewall_rule" "allow_all_ips" {
  name                = "AllowAllIPs"
  server_id           = azurerm_postgresql_server.dbserver.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}
