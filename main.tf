terraform {
  required_version = "~>1.4.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.66.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_resource_group" "rg" {
  name     = "1-fbde0e42-playground-sandbox"
  location = "West US"
  tags = {
    environment = "dev"
  }

}
resource "azurerm_storage_account" "storage" {
  name                     = "mondayparacetamole"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "demo-vm" {

  name                = "demo-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}
resource "azurerm_subnet" "demo-subnet" {

  name                 = "demo-subnet"
  virtual_network_name = azurerm_virtual_network.demo-vm.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.123.1.0/24"]
}

resource "azurerm_network_security_group" "demo-sg" {

  name                = "demo-sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "demo-dev-rule" {

  name                        = "demo-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.demo-sg.name
}

resource "azurerm_subnet_network_security_group_association" "demo-sga" {
  subnet_id                 = azurerm_subnet.demo-subnet.id
  network_security_group_id = azurerm_network_security_group.demo-sg.id
}

resource "azurerm_public_ip" "demo-pubip" {
  name                = "demo-pubip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "demo-interface" {

  name                = "demo-interface"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {

    name                          = "internal"
    subnet_id                     = azurerm_subnet.demo-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.demo-pubip.id
  }
  tags = {
    environment = "dev"
  }

}
resource "azurerm_linux_virtual_machine" "demo-vm" {
  name                  = "demo-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.demo-interface.id]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("/Users/amlan/Desktop/TerrafromBasic/demoazurekey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

data "azurerm_public_ip" "demo-ip-data" {

  name                = azurerm_public_ip.demo-pubip.name
  resource_group_name = azurerm_resource_group.rg.name

}

output "public_ip_address" {

  value = "${azurerm_linux_virtual_machine.demo-vm.name}: ${data.azurerm_public_ip.demo-ip-data.ip_address}"

}
