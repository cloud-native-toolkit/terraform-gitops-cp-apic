module "gitops_module" {
  source = "./module"
  depends_on = [module.apic,module.cp4i-dependencies]
  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  #kubeseal_cert = module.gitops.sealed_secrets_cert
  kubeseal_cert = module.cert.cert
  entitlement_key = var.cp_entitlement_key
  apic_version = module.cp4i-dependencies.apic.version
  license_id = module.cp4i-dependencies.apic.license
  usage = module.cp4i-dependencies.apic.license_use
  storage_class="portworx-db2-rwo-sc"
}
