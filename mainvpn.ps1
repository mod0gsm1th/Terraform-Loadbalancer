##### This terraform creates local VNET(on-prem) gateway and VPN gateway, connects VNET to VNET with on-prem 
#####  VPN to europe gateway and VPN  #######

resource "azurerm_resource_group" "MDSVPN" {
  name     = "MDSVPNGWT"
  location = "east us"
}

resource "azurerm_virtual_network" "MDSVET4" {
  name                = "MDSVPN-vnet"
  location            = azurerm_resource_group.MDSVPN.location
  resource_group_name = azurerm_resource_group.MDSVPN.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "MDSVPN_subnet4" {
  name                 = "MDSVPN-GatewaySubnet"
  resource_group_name  = azurerm_resource_group.MDSVPN.name
  virtual_network_name = azurerm_virtual_network.MDSVET4.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_local_network_gateway" "MDSVPN_Local_onpremise4" {
  name                = "Local-GTWY-onpremise"
  location            = azurerm_resource_group.MDSVPN.location
  resource_group_name = azurerm_resource_group.MDSVPN.name
  gateway_address     = "168.62.225.23"
  address_space       = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "MDSVPN_PIP4" {
  name                = "public-IP4-VPN"
  location            = azurerm_resource_group.MDSVPN.location
  resource_group_name = azurerm_resource_group.MDSVPN.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "MDSVPN_VPN" {
  name                = "MDSVPN-4"
  location            = azurerm_resource_group.MDSVPN.location
  resource_group_name = azurerm_resource_group.MDSVPN.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.MDSVPN_PIP4.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.MDSVPN_subnet4.id
  }
}

resource "azurerm_virtual_network_gateway_connection" "MDSVPN_onpremise" {
  name                = "MDSVPN-CON-onpremise"
  location            = azurerm_resource_group.MDSVPN.location
  resource_group_name = azurerm_resource_group.MDSVPN.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.MDSVPN_VPN.id
  local_network_gateway_id   = azurerm_local_network_gateway.MDSVPN_Local_onpremise4.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

###########################################################################
resource "azurerm_resource_group" "MDS_us" {
  name     = "us"
  location = "East US"
}
resource "azurerm_virtual_network" "MDS_us_vnet" {
  name                = "us"
  location            = azurerm_resource_group.MDS_us.location
  resource_group_name = azurerm_resource_group.MDS_us.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "MDS_us_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.MDS_us.name
  virtual_network_name = azurerm_virtual_network.MDS_us_vnet.name
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "MDS_PIP_us" {
  name                = "us"
  location            = azurerm_resource_group.MDS_us.location
  resource_group_name = azurerm_resource_group.MDS_us.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "MDS_us_Gateway" {
  name                = "us-gateway"
  location            = azurerm_resource_group.MDS_us.location
  resource_group_name = azurerm_resource_group.MDS_us.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "Basic"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.MDS_PIP_us.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.MDS_us_Gateway.id
  }
}
################  configure Euroe VPN connection ####################
resource "azurerm_resource_group" "MDS_europe" {
  name     = "europe"
  location = "West Europe"
}

resource "azurerm_virtual_network" "MDS_europe_net" {
  name                = "europe"
  location            = azurerm_resource_group.MDS_europe.location
  resource_group_name = azurerm_resource_group.MDS_europe.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "MDS_europe_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.MDS_europe.name
  virtual_network_name = azurerm_virtual_network.MDS_europe_net.name
  address_prefix       = "10.1.1.0/24"
}

resource "azurerm_public_ip" "MDS_PIP_europe" {
  name                = "europe"
  location            = azurerm_resource_group.MDS_europe.location
  resource_group_name = azurerm_resource_group.MDS_europe.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "MDS_europe_gatewy" {
  name                = "europe-gateway"
  location            = azurerm_resource_group.MDS_europe.location
  resource_group_name = azurerm_resource_group.MDS_europe.name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = "Basic"

  ip_configuration {
    public_ip_address_id          = azurerm_public_ip.MDS_PIP_europe.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.MDS_europe_subnet.id
  }
}

resource "azurerm_virtual_network_gateway_connection" "MDS_us_to_europe" {
  name                = "us-to-europe"
  location            = azurerm_resource_group.us.location
  resource_group_name = azurerm_resource_group.us.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.MDS_us_Gateway.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.MDS_europe_gatewy.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}

resource "azurerm_virtual_network_gateway_connection" "MDS_europe_to_us" {
  name                = "europe-to-us"
  location            = azurerm_resource_group.MDS_europe.location
  resource_group_name = azurerm_resource_group.MDS_europe.name

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.MDS_europe_gatewy.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.MDS_us_Gateway.id

  shared_key = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"
}