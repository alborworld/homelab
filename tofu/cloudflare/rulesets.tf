resource "cloudflare_ruleset" "terraform_managed_resource_f0c330719edd47928b3f23baaa4e22c7_0" {
  kind    = "zone"
  name    = "default"
  phase   = "http_request_dynamic_redirect"
  zone_id = var.cloudflare_zone_id
  rules = [{
    action = "redirect"
    action_parameters = {
      from_value = {
        preserve_query_string = true
        status_code           = 301
        target_url = {
          value = "https://mail.google.com"
        }
      }
    }
    description  = "Redirect mail.alborworld.com to Gmail"
    enabled      = true
    expression   = "(http.host eq \"mail.alborworld.com\")"
    id           = null
    last_updated = "2025-05-07T11:46:01.153837Z"
    ref          = "d4bd70c911f7496c9c7df6344d2f57e5"
    version      = "1"
  }]
}