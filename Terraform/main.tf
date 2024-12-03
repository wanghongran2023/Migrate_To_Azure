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

    app_command_line = "apt-get update && apt-get install -y build-essential g++ libffi-dev cmake libssl-dev && pip install --upgrade pip setuptools wheel && pip install --no-cache-dir -r requirements.txt && gunicorn --bind 0.0.0.0:8000 --workers 3 application:app"
    application_stack {
      python_version = "3.10"
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

resource "azurerm_servicebus_queue" "notificationqueue" {
  name                = "notificationqueue"
  namespace_id        = azurerm_servicebus_namespace.servicebus.id
  enable_partitioning    = false
  requires_duplicate_detection = false
  max_size_in_megabytes   = 1024
}

data "azurerm_servicebus_namespace_authorization_rule" "root_manage_access_key" {
  name                = "RootManageSharedAccessKey"
  namespace_id        = azurerm_servicebus_namespace.servicebus.id
}

output "service_bus_connection_string" {
  value     = data.azurerm_servicebus_namespace_authorization_rule.root_manage_access_key.primary_connection_string
  sensitive = true
}

resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_config.name
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}



resource "azurerm_linux_function_app" "function" {
  name                = var.function_config.name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  service_plan_id = azurerm_service_plan.app_service_plan.id
  storage_account_name = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key

  site_config {
    always_on        = true
    application_stack {
      python_version = "3.9"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    SERVICE_BUS_CONNECTION_STRING  = azurerm_servicebus_namespace.servicebus.default_primary_connection_string
    SERVICE_BUS_QUEUE_NAME         = azurerm_servicebus_queue.notificationqueue.name
  }
}

resource "azurerm_role_assignment" "servicebus_receiver" {
  principal_id         = azurerm_linux_function_app.function.identity.0.principal_id
  role_definition_name = "Azure Service Bus Data Receiver"
  scope                = azurerm_servicebus_namespace.servicebus.id
}
