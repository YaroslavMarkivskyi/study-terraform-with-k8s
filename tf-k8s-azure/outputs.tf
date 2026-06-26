output "jumpbox_public_ip" {
  value       = azurerm_public_ip.jumpbox_pip.ip_address
  description = "Публічна IP-адреса Jumpbox для входу"
}

output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}