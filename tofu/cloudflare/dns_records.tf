# Cloudflare DNS for alborworld.com — declared as DATA, not as one resource
# block per record. Adding a record is one line in local.dns below.
#
# CONVENTIONS (please keep):
#   * _acme-challenge.* records are deliberately NOT declared. Traefik creates and
#     removes them on the fly via the Cloudflare DNS-01 solver, and tofu ignores
#     what it does not declare. A cf-terraforming export once captured four of them
#     as if permanent, with hardcoded tokens; those fossils are gone. Do not
#     re-import them.
#   * _github-pages-challenge-alborworld is also left unmanaged, so an accidental
#     destroy cannot drop GitHub's domain-takeover protection.
#   * zone_id comes from var.cloudflare_zone_id (variables.tf marks it sensitive),
#     matching rulesets.tf. Never hardcode it.
#   * ftp / ssh / mysql A records pointed at DreamHost shared hosting and were
#     removed 2026-08-21 when the site moved to GitHub Pages. They were also
#     proxied, which could never have worked — Cloudflare proxies only HTTP/HTTPS
#     ports, not 21/22/3306.

locals {
  # proxied defaults to false; priority applies to MX only.
  dns = {
    # apex -> GitHub Pages. MUST stay unproxied: GitHub terminates TLS with its own
    #   Let's Encrypt cert. Cloudflare flattens this CNAME at the apex.
    apex = { name = "alborworld.com", type = "CNAME", content = "alborworld.github.io" }
    # www -> GitHub Pages, which 301s www to the apex.
    www = { name = "www.alborworld.com", type = "CNAME", content = "alborworld.github.io" }
    # mail MUST stay proxied: the Gmail redirect in rulesets.tf is a dynamic-redirect
    #   rule, and those only fire on proxied traffic. The googlehosted target is
    #   never actually reached.
    mail            = { name = "mail.alborworld.com", type = "CNAME", content = "ghs.googlehosted.com", proxied = true }
    mx_aspmx_l_10   = { name = "alborworld.com", type = "MX", content = "ASPMX.L.GOOGLE.com", priority = 10 }
    mx_alt1_20      = { name = "alborworld.com", type = "MX", content = "ALT1.ASPMX.L.GOOGLE.com", priority = 20 }
    mx_alt2_20      = { name = "alborworld.com", type = "MX", content = "ALT2.ASPMX.L.GOOGLE.com", priority = 20 }
    mx_aspmx2_30    = { name = "alborworld.com", type = "MX", content = "ASPMX2.GOOGLEMAIL.com", priority = 30 }
    mx_aspmx3_30    = { name = "alborworld.com", type = "MX", content = "ASPMX3.GOOGLEMAIL.com", priority = 30 }
    mx_aspmx4_30    = { name = "alborworld.com", type = "MX", content = "ASPMX4.GOOGLEMAIL.com", priority = 30 }
    mx_aspmx5_30    = { name = "alborworld.com", type = "MX", content = "ASPMX5.GOOGLEMAIL.com", priority = 30 }
    txt_spf         = { name = "alborworld.com", type = "TXT", content = "\"v=spf1 include:_spf.google.com ~all\"" }
    txt_keybase     = { name = "alborworld.com", type = "TXT", content = "\"keybase-site-verification=ZfqNa4OaJ58v8YNJpS50m1sbgCNryiheqQPqLqRZ06w\"" }
    txt_dmarc       = { name = "_dmarc.alborworld.com", type = "TXT", content = "\"v=DMARC1; p=quarantine; rua=mailto:alessandro+dmarc-reports@alborworld.com; ruf=mailto:alessandro+dmarc-reports@alborworld.com; sp=quarantine; adkim=s; aspf=s\"" }
    txt_dkim_google = { name = "google._domainkey.alborworld.com", type = "TXT", content = "\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyG2X6lmvLy4sGZ2xK/cYSn5hT1u7QWw+YLD+nx3a1jAYuaZaKkq6JsDdRNYnIB3N1M0d6gxB/ZhYcODB6jf1922Gt+DSCHav7PE3CDb7+OkVXgpDdF67H/o2roTFrmyfreawy12v4uJ8z7r6HS2CnmPTwtH+CgrKCFCDyQHsWrEt45qZ4YaLh/Y2+z5hzf/bh\" \"ur+GpyAD15TLcUFiL71sjyQURqJnY30ioYXXq/vigq0qtS3tlpsEMJz4yzsTH5wZ3WUjHOp9VJpiAAuFadD8DibY3idj283Di0S9gBRfN6OrgT10N3pvkqV3WgxTGpE+zfjSLD9mDrl3ztrFZO4xwIDAQAB\"" }
  }
}

resource "cloudflare_dns_record" "this" {
  for_each = local.dns

  zone_id  = var.cloudflare_zone_id
  name     = each.value.name
  type     = each.value.type
  content  = each.value.content
  priority = try(each.value.priority, null)
  proxied  = try(each.value.proxied, false)
  ttl      = 1
  tags     = []
  settings = {}
}
