# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "8afbe872-4126-415f-bbf5-59890b64e029"
    client_id       = "7838c180-37d1-4ef8-a13b-b872a00d5c96"
    client_secret   = "1R3a43RH=hR=@A[H4_3I?xpQIjB9.6y="
    tenant_id       = "6e06e42d-6925-47c6-b9e7-9581c7ca302a"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "DemoResource-GroupName" {
    name     = "${var.prefix}"
    location = "eastus"

    tags = {
        environment = "Terraform MAY-LAB"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "Demo-network" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.DemoResource-GroupName.name

    tags = {
        environment = "Terraform G1"
    }
}

# Create subnet
resource "azurerm_subnet" "Demosubnet" {
    name                 = "DemoSubnet"
    resource_group_name  = azurerm_resource_group.DemoResource-GroupName.name
    virtual_network_name = azurerm_virtual_network.DemoSubnetnetwork.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "Demopublicip" {
    name                         = "DemoPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.DemoResource-GroupNam.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform G2"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "DEMOnsg" {
    name                = "DEMONetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.DemoResource-GroupName.name
    
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

    tags = {
        environment = "Terraform G3"
    }
}

# Create network interface
resource "azurerm_network_interface" "DEMOnic" {
    name                      = "DEMONIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.DemoResource-GroupName.name
    network_security_group_id = azurerm_network_security_group.DEMOnsg.id

    ip_configuration {
        name                          = "DEMONicConfiguration"
        subnet_id                     = azurerm_subnet.DEMOsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.DEMOpublicip.id
    }

    tags = {
        environment = "Terraform G4"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.DemoResource-GroupName.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "DEMOstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.DemoResource-GroupName.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform G5"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "DEMOvm" {
    name                  = "DEMOVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.DemoResource-GroupName.name
    network_interface_ids = [azurerm_network_interface.DEMOnic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "DEMOOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "OpenLogic"
        offer     = "CentOS"
        sku       = "7.5"
        version   = "latest"
    }

    os_profile {
        computer_name  = "Demo-vm"
        admin_username = "Admin"
        admin_password = "P@ssw0rd1234!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.DEMOstorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform G6"
    }
}





