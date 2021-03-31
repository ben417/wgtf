output "vm_pub_ip" {
  value = data.azurerm_public_ip.pip.ip_address
}
