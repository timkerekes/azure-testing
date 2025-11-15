resource "azurerm_resource_group" "main" {
  name     = "main"
  location = "East US"
}

resource "azurerm_network_security_group" "app" {
  name                = "app-security-group"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "sql" {
  name                = "sql-security-group"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "main" {
  name                = "main-network"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  subnet {
    name             = "app-subnet"
    address_prefixes = ["10.0.1.0/24"]
    security_group   = azurerm_network_security_group.app.id
  }

  subnet {
    name             = "sql-subnet"
    address_prefixes = ["10.0.2.0/24"]
    security_group   = azurerm_network_security_group.sql.id
  }

  tags = {
    environment = "Production"
  }
}

resource "random_password" "admin_password" {
  length      = 20
  special     = true
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}

resource "azurerm_mssql_server" "main" {
  name                         = "main-sqlserver"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = random_password.admin_password.result
}

resource "azurerm_mssql_database" "main" {
  name         = "main-db"
  server_id    = azurerm_mssql_server.main.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"

  tags = {
    environment = "Production"
  }

  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = true
  }
}