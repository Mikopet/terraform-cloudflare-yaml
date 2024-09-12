resource "cloudflare_record" "record" {
  for_each = local.dns_records

  zone_id = var.zone_id
  type    = each.value.type
  name    = each.value.name

  ttl             = try(each.value.ttl, 1) # 1 = Automatic
  allow_overwrite = try(each.value.allow_overwrite, false)
  proxied         = try(each.value.proxied, false)

  content  = try(each.value.content, null)
  priority = try(each.value.priority, null)
  comment  = try(each.value.comment, null)

  dynamic "data" {
    for_each = try([each.value.data], [])

    content {
      service  = try(data.value.service, null)
      proto    = try(data.value.proto, null)
      name     = try(data.value.name, null)
      priority = try(data.value.priority, null)
      weight   = try(data.value.weight, null)
      port     = try(data.value.port, null)
      target   = try(data.value.target, null)
    }
  }
}

