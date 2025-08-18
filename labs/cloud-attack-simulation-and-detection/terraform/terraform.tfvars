# =======================================================
# Cloud Attack Simulation & Detection Lab
# =======================================================

resource_group_name = "rg-cloud-attack-sim"
location            = "eastus"
prefix              = "cloudattacklab"

tags = {
  owner       = "portfolio"
  environment = "lab"
  project     = "cloud-attack-simulation"
  compliance  = "CIS/NIST"
}
