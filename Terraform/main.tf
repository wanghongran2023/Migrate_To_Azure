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
  features {} # Required for azurerm 3.x
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_config.name
  location = var.resource_group_config.location
}

resource "azurerm_postgresql_server" "dbserver" {
  name                         = var.db_server_config.name
  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = azurerm_resource_group.resource_group.location
  version                      = "10"
  administrator_login          = var.db_server_config.user
  administrator_login_password = var.db_server_config.password

  sku_name = "B_Gen5_1"
  storage_mb             = 5120
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
  ssl_enforcement_enabled = true

  depends_on = [azurerm_resource_group.resource_group]
}

resource "azurerm_postgresql_database" "db" {
  name                = var.db_config.name
  resource_group_name = azurerm_resource_group.resource_group.name
  server_name         = azurerm_postgresql_server.dbserver.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_postgresql_firewall_rule" "allow_azure_ips" {
  name       = "AllowAzureServices"
  server_name = azurerm_postgresql_server.dbserver.name
  resource_group_name = azurerm_resource_group.resource_group.name
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_firewall_rule" "allow_all_ips" {
  name       = "AllowAllIPs"
  server_name = azurerm_postgresql_server.dbserver.name
  resource_group_name = azurerm_resource_group.resource_group.name
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}
