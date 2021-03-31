# Main resource group containing all the VPN resources
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.application}-${var.environment}"
  location = var.location
}

# VNET
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.application}-${var.environment}"
  address_space       = [var.vnet_addr_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "snet-${var.application}-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_addr_space, var.snet_add_bits, 0)]
}

# Public IP for VPN server virtual machine
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.application}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

# Network interface for VPN server virtual machine
resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.application}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "niccfg-${var.application}-${var.environment}"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# VPN server virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "vm-${var.application}-${var.environment}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "vm-osdisk-${var.application}-${var.environment}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "${var.application}${var.environment}"
    admin_username = "deploy"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("~/.ssh/id_rsa.pub")
      path     = "/home/deploy/.ssh/authorized_keys"
    }
  }
}

data "azurerm_public_ip" "pip" {
  name                = azurerm_public_ip.pip.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [
    azurerm_virtual_machine.vm
  ]
}