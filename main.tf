

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "DemoResource" {
    name     = "${var.prefix}"
    location = "eastus"

    tags = {
        environment = "Terraform DemoToday"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "Demonetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.DemoResource.name

    tags = {
        environment = "Terraform DemoToday"
    }
}

# Create subnet
resource "azurerm_subnet" "Demosubnet" {
    name                 = "NameDemoSubnet"
    resource_group_name  = azurerm_resource_group.DemoResource.name
    virtual_network_name = azurerm_virtual_network.Demonetworknetwork.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "Demopublicip" {
    name                         = "NameDemoPublicIP"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.DemoResource.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform DemoToday"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "Demonsg" {
    name                = "NameDemoNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.DemoResource.name
    
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
        environment = "Terraform DemoToday""
    }
}

# Create network interface
resource "azurerm_network_interface" "Demonic" {
    name                      = "NameDemoNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.DemoResource.name
    network_security_group_id = azurerm_network_security_group.Demonsg.id

    ip_configuration {
        name                          = "DemoNicConfiguration"
        subnet_id                     = azurerm_subnet.Demosubnetsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.Demopublicippublicip.id
    }

    tags = {
        environment = "Terraform DemoToday""
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.DemoResource.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "Demostorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.DemoResource.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform DemoToday""
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "Demovm" {
    name                  = "NameDemoVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.DemoResource.name
    network_interface_ids = [azurerm_network_interface.Demonicnic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "DemoLABOsDisk"
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
        computer_name  = "Demovm"
        admin_username = "Admin"
        admin_password = "P@ssw0rd1234!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.Demostorageaccountstorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform DemoToday""
    }
}
