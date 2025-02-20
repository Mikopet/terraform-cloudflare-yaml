resource "cloudflare_dns_record" "record" {
  for_each = local.dns_records

  zone_id = var.zone_id
  type    = each.value.type
  name    = each.value.name

  ttl     = try(each.value.ttl, 1) # 1 = Automatic
  proxied = try(each.value.proxied, false)

  content  = try(each.value.content, null)
  priority = try(each.value.priority, null)
  comment  = try(each.value.comment, null)

  data = try(each.value.data, null)
}

