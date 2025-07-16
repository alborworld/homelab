# Ubuntu Cloud Image
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
    content_type = "iso"
    datastore_id = var.proxmox_datastore_name
    node_name    = var.proxmox_node_name
    upload_timeout = 2500

    url = "https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img"
}