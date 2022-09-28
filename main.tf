locals {
  name          = "ibm-cp4i-apic-instance"
  bin_dir       = module.setup_clis.bin_dir
  chart_dir     = "${path.module}/charts/${local.name}"
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  service_url   = "http://${local.name}.${var.namespace}"
  values_content = {
    ibm_apic_instance = {
      name = "apicinstance"
      namespace = var.namespace
      license = {
        accept = true
        use = var.usage
        license_id = var.license_id
      }
      profile = var.profile
      version = var.apic_version
      storageClass = var.storage_class
    }
  }
  layer = "services"
  type  = "instances"
  application_branch = "main"
  namespace = var.namespace
  layer_config = var.gitops_config[local.layer]
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource gitops_pull_secret cp_icr_io {
  name = "ibm-entitlement-key"
  namespace = var.namespace
  server_name = var.server_name
  branch = local.application_branch
  layer = local.layer
  credentials = yamlencode(var.git_credentials)
  config = yamlencode(var.gitops_config)
  kubeseal_cert = var.kubeseal_cert


  secret_name = "ibm-entitlement-key"
  registry_server = "cp.icr.io"
  registry_username = "cp"
  registry_password = var.entitlement_key
}

resource null_resource create_instance_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.chart_dir}' '${local.yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource gitops_module module {
  depends_on = [null_resource.create_instance_yaml]


  name = local.name
  namespace = local.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
