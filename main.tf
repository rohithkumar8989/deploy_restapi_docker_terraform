provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "linux-dev-RG"
  location = "West US"
}

# Create virtual network
resource "azurerm_virtual_network" "linux_dev_network" {
  name                = "linux-dev-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.linux-dev-rg.location
  resource_group_name = azurerm_resource_group.linux-dev-rg.name
}

# Create subnet
resource "azurerm_subnet" "dev-subnet" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.linux-dev-rg.name
  virtual_network_name = azurerm_virtual_network.dev-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "dev-ip" {
  name                = "dev-ip"
  location            = azurerm_resource_group.linux-dev-rg.name
  resource_group_name = azurerm_resource_group.linux-dev-rg.location
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_interface" "dev-nic" {
  name                      = "dev-nic"
  location                  = azurerm_resource_group.linux-dev-rg.location
  resource_group_name       = azurerm_resource_group.linux-dev-rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev-ip.id
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "dev-vm" {
  name                  = "dev-vm"
  location              = azurerm_resource_group.linux-dev-rg.location
  resource_group_name   = azurerm_resource_group.linux-dev-rg.name
  network_interface_ids = [azurerm_network_interface.dev-nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "dev-vm-osdisk"
    caching           = "ReadWrite"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "dev-vm"
    admin_username = "adminuser"
    disable_password_authentication = true
	}
	
	admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.secureadmin_ssh.public_key_openssh
	}

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
	  "sudo docker run -d -p 3000:3000 rest-api"
    ]
  }
}
