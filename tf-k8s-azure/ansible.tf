resource "local_file" "ssh_private_key_file" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/k8s_id_rsa"
  file_permission = "0600"
}

resource "local_file" "machines_txt" {
  content = join("\n", concat(
    [for name in sort(keys(var.internal_nodes)) :
      trimspace("${var.internal_nodes[name].ip} ${name}.kubernetes.local ${name}${var.internal_nodes[name].pod_subnet != "" ? " ${var.internal_nodes[name].pod_subnet}" : ""}")
    ],
    [""]
  ))
  filename = "${path.module}/../ansible/machines.txt"
}

resource "local_file" "ansible_inventory" {
  content  = <<-EOT
    [jumpbox]
    jumpbox ansible_host=${azurerm_public_ip.jumpbox_pip.ip_address} ansible_user=${var.admin_username} ansible_ssh_private_key_file=../tf-k8s-azure/k8s_id_rsa ansible_ssh_common_args='-o StrictHostKeyChecking=no'

    [nodes]
    %{~ for name, node in var.internal_nodes }
    ${name} ansible_host=${node.ip} ansible_user=${var.admin_username} ansible_ssh_private_key_file=../tf-k8s-azure/k8s_id_rsa ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -W %h:%p -i ../tf-k8s-azure/k8s_id_rsa -o StrictHostKeyChecking=no ${var.admin_username}@${azurerm_public_ip.jumpbox_pip.ip_address}"'
    %{~ endfor }
    EOT
  filename = "${path.module}/../ansible/hosts.ini"
}

resource "null_resource" "ansible_jumpbox" {
  depends_on = [
    azurerm_linux_virtual_machine.jumpbox,
    local_file.ansible_inventory,
    local_file.ssh_private_key_file,
    local_file.machines_txt,
  ]

  triggers = {
    vm_id = azurerm_linux_virtual_machine.jumpbox.id
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<-EOT
      until nc -zw 5 ${azurerm_public_ip.jumpbox_pip.ip_address} 22; do
        echo "Waiting for SSH on jumpbox..."
        sleep 5
      done
      ansible-playbook -i ../ansible/hosts.ini ../ansible/setup_jumpbox.yml
    EOT
  }
}

resource "null_resource" "ansible_nodes" {
  depends_on = [null_resource.ansible_jumpbox]

  triggers = {
    node_ids = join(",", [for vm in azurerm_linux_virtual_machine.nodes : vm.id])
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "ansible-playbook -i ../ansible/hosts.ini --timeout 60 ../ansible/setup_nodes.yml"
  }
}
