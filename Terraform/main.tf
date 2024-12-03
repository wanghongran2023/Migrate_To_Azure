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

resource "azurerm_postgresql_flexible_server" "dbserver" {
  name                = var.db_server_config.name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  sku_name = "B_Standard_B1ms"
  storage_mb             = 32768
  version                = "13"
  administrator_login    = var.db_server_config.user
  administrator_password = var.db_server_config.password

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  public_network_access_enabled = true

  depends_on = [azurerm_resource_group.resource_group]
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name           = var.db_config.name
  server_id      = azurerm_postgresql_flexible_server.dbserver.id
  charset        = "UTF8"
  collation      = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_ips" {
  name       = "AllowAzureServices"
  server_id  = azurerm_postgresql_flexible_server.dbserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all_ips" {
  name       = "AllowAllIPs"
  server_id  = azurerm_postgresql_flexible_server.dbserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = "python-app-service-plan"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "P0v3"
  os_type             = "Linux"
}

resource "azurerm_linux_web_app" "linux_webapp" {
  name                = var.app_config.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  auth_settings {
    enabled = false
  }
  
  site_config {
    always_on        = true

    app_command_line = "apt-get update && apt-get install -y build-essential g++ && pip install -r requirements.txt && gunicorn --bind 0.0.0.0:8000 --workers 3 application:app"
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = { 
  }
}

resource "azurerm_servicebus_namespace" "servicebus" {
  name                = var.servicebus_config.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_namespace_authorization_rule" "servicebus_authorization_rule" {
  name                = "RootManageSharedAccessKey"
  namespace_name      = azurerm_servicebus_namespace.servicebus.name
  resource_group_name = azurerm_resource_group.resource_group.name
  listen              = true
  send                = true
  manage              = true
}

output "service_bus_connection_string" {
  value = azurerm_servicebus_namespace_authorization_rule.servicebus_authorization_rule.primary_connection_string
  sensitive = true
}
