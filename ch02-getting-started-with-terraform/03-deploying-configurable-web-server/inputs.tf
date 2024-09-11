variable "compartment_id" {
  description = "The OCID of the tenancy used to deploy resources into."
  type = string
  sensitive = true
  default = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
}

variable "web_server_port" {
  description = "The TCP port that the web server listens on."
  type = number
  default = 8080
}

variable "ol8_8_10_2024_07_31_1_uk_london_1_image_id" {
  description = "The OCID of the Oracle-Linux-8.10-2024.07.31-0 platform image in uk-london-1"
  type = string
  default = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa"
}
