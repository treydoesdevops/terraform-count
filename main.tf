provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "CountDemo"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "count-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/26"]
}

resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "nic-${count.index + 1}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.subnet]
}

#The count parameter is used to create multiple instances of a resource. 
#We can reference count.index within the names of the resources to append the index
resource "azurerm_virtual_machine" "vm" {
  count                 = 2
  name                  = "vm-${count.index + 1}"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname${count.index}"
    admin_username = "trey"
    admin_password = "ASecurePassword1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}