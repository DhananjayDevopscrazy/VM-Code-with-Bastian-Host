resource "azurerm_resource_group" "rg" {
  name     = "DJRG"
  location = "Central India"
}

resource "azurerm_public_ip" "PublicIP" {
  depends_on = [ azurerm_resource_group.rg ]
  name                = "avmpip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
resource "azurerm_virtual_network" "vnet" {
  depends_on          = [azurerm_public_ip.PublicIP]
  name                = "vnet01"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "mysubnet" {
  depends_on           = [azurerm_subnet.Bsubnet]
  name                 = "subnet01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/25"]
}
resource "azurerm_subnet" "Bsubnet" {
  depends_on = [ azurerm_virtual_network.vnet ]
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.128/26"]
}

resource "azurerm_bastion_host" "bastianhost" {
  depends_on = [ azurerm_subnet.Bsubnet ]
  name                = "mybastianhost"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.Bsubnet.id
    public_ip_address_id = azurerm_public_ip.PublicIP.id
  }
}

resource "azurerm_network_interface" "network" {
  depends_on = [ azurerm_bastion_host.bastianhost ]
  name                = "vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mysubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "server" {
  depends_on          = [azurerm_network_interface.network]
  name                = "linux-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  network_interface_ids = [
    azurerm_network_interface.network.id,
  ]

  admin_username                  = "superuser"
  admin_password                  = "India@123"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
