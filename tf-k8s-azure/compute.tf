resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "jumpbox"
  resource_group_name = azurerm_resource_group.k8s_rg.name
  location            = azurerm_resource_group.k8s_rg.location
  size                = "Standard_B1ls"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "nodes" {
  for_each            = var.internal_nodes
  name                = each.key
  resource_group_name = azurerm_resource_group.k8s_rg.name
  location            = azurerm_resource_group.k8s_rg.location
  size                = each.value.size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.internal_nic[each.key].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = each.value.disk
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12-gen2"
    version   = "latest"
  }
}