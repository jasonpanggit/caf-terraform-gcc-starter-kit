# Cognitive Servies
variable "cognitive_services" {
  description = "cognitive service configuration objects"
  default = {
    # cognitive_services_account = {}
  }
}

variable "cognitive_services_account" {
  default = {}
}

variable "cognitive_deployments" {
  default = {}
}

variable "search_services" {
  default = {}
}