output "VM_PUB_IP" {
  value = oci_core_instance.this.public_ip
}

output "VM_PRIV_IP" {
  value = oci_core_instance.this.private_ip
}
# output "image_ids" {
#   value = data.oci_core_images.gpu_images.images[*].id
# }

# output "image_details" {
#   value = data.oci_core_images.gpu_images.images
# }