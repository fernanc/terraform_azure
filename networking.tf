# 1 - Vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = "fernanc"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_network_interface" "nic" {
  name                = "example-nic"
  location            = "francecentral"
  resource_group_name = "fernanc"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_security_group" "nsg" {
  name                = "example-nsg"
  location            = "francecentral"
  resource_group_name = "fernanc"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "AppOnPort5000"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_public_ip" "lb_pubip" {
  name                = "example-lb-pubip"
  location            = "francecentral"
  resource_group_name = "fernanc"
  allocation_method   = "Static"
  domain_name_label   = "fernanc-dns-name"
}
resource "azurerm_lb" "example_lb" {
  name                = "example-lb"
  location            = "francecentral"
  resource_group_name = "fernanc"

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pubip.id
  }
}
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.example_lb.id
  name            = "backendAddressPool"
}
resource "azurerm_network_interface_backend_address_pool_association" "nic_to_backendpool" {
  network_interface_id    = azurerm_network_interface.nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}
resource "azurerm_lb_rule" "lb_rule_5000" {
  loadbalancer_id               = azurerm_lb.example_lb.id
  name                          = "Port5000Access"
  protocol                      = "Tcp"
  frontend_port                 = 5000
  backend_port                  = 5000
  frontend_ip_configuration_name = "publicIPAddress"
  backend_address_pool_ids      = [azurerm_lb_backend_address_pool.backend_pool.id]
}
output "public_ip_loadbalancer" {
  value = azurerm_public_ip.lb_pubip.id
  description = "The private IP address of the newly created Azure VM"
}
