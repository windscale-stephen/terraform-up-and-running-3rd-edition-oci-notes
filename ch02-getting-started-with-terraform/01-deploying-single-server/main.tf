provider "oci" {
  auth = "APIKey"
  config_file_profile = "DEFAULT"
}

resource "oci_core_vcn" "example_vcn" {
  compartment_id = "<tenancy_ocid>"
  cidr_blocks = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "example_subnet" {
  cidr_block = "10.0.1.0/24"
  compartment_id = "<tenancy_ocid>"
  vcn_id = oci_core_vcn.example_vcn.id
  prohibit_public_ip_on_vnic = true # Make this a private subnet
}

resource "oci_core_instance" "example_instance" {
  availability_domain = "Lguh:UK-LONDON-1-AD-3"
  compartment_id = "<tenancy_ocid>"
  shape = "VM.Standard.E2.1.Micro"
  source_details {
    source_id = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa"
    # Oracle-Linux-8.10-2024.07.31-0 in uk-london-1
    source_type = "image"
  }
  create_vnic_details {
    subnet_id = oci_core_subnet.example_subnet.id
    assign_public_ip = false # Shouldn't need this because prohibit_public_ip_on_vnic = true in
                             # subnet
  }
  preserve_boot_volume = false
}
