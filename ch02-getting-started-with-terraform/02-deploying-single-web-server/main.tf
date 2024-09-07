provider "oci" {
  auth = "APIKey"
  config_file_profile = "DEFAULT"
}

resource "oci_core_vcn" "example_vcn" {
  display_name = "example_vcn"
  compartment_id = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
  cidr_blocks = ["10.0.0.0/16"]
}

resource "oci_core_internet_gateway" "example_internet_gw" {
  display_name = "example_internet_gw"
  compartment_id = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
  vcn_id = oci_core_vcn.example_vcn.id
  enabled = true
}

# "Magic" for updating the default route table of the VCN from:
# https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformbestpractices_topic-vcndefaults.htm
resource "oci_core_default_route_table" "example_vcn_default_routetable" {
  display_name = "Default Route Table for example_vcn"
  manage_default_resource_id = oci_core_vcn.example_vcn.default_route_table_id
  compartment_id = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
  route_rules {
    destination_type = "CIDR_BLOCK"
    destination = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.example_internet_gw.id
  }
}

# "Magic" for updating the default security list of the VCN from:
# https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformbestpractices_topic-vcndefaults.htm
resource "oci_core_default_security_list" "example_vcn_default_securitylist" {
  display_name = "Default Security List for example_vcn"
  manage_default_resource_id = oci_core_vcn.example_vcn.default_security_list_id
  compartment_id = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
  egress_security_rules {
    stateless = false
    destination = "0.0.0.0/0"
    protocol = "all"
  }
  ingress_security_rules {
    stateless = false
    source = "0.0.0.0/0"
    protocol = 6 # TCP
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    stateless = false
    source = "0.0.0.0/0"
    protocol = 1 # ICMP
    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    stateless = false
    source = "0.0.0.0/0"
    protocol = 1 # ICMP
    icmp_options {
      type = 3
    }
  }
  ingress_security_rules {
    stateless = false
    source = "0.0.0.0/0"
    protocol = 6 # TCP
    tcp_options {
      min = 8080
      max = 8080
    }
  }
}

resource "oci_core_subnet" "example_public_subnet" {
  display_name = "example_public_subnet"
  cidr_block = "10.0.0.0/24"
  compartment_id = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
  vcn_id = oci_core_vcn.example_vcn.id
  prohibit_internet_ingress = false
}

resource "oci_core_instance" "example_webserver" {
  display_name = "example_webserver"
  availability_domain = "Lguh:UK-LONDON-1-AD-3"
  compartment_id = "ocid1.tenancy.oc1.<rest_of_tenancy_ocid>"
  shape = "VM.Standard.E2.1.Micro"
  source_details {
    source_id = "ocid1.image.oc1.uk-london-1.aaaaaaaay6agryw3wg52ruxw56zns3azgwgki3ireaugsuhmfvfnjplxsrfa"
    source_type = "image"
  }
  create_vnic_details {
    subnet_id = oci_core_subnet.example_public_subnet.id
    assign_public_ip = true
  }
  metadata = {
    user_data = filebase64("./user_data.sh")
  }
  preserve_boot_volume = false
}
