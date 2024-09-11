output "example_server_public_ip" {
  description = "The public IP address of the web server instance."
  value = oci_core_instance.example_webserver.public_ip
}
