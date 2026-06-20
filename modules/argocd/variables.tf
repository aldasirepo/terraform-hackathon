variable "tags"               { type = map(string) }
variable "argocd_namespace"   { type = string; default = "argocd" }
variable "argocd_chart_version" { type = string; default = "6.7.14" }
variable "cd_apps_path"       { type = string }
