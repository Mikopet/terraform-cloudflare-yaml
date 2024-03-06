locals {
  dns_records = merge([
    for type, outer_value in var.records : tomap({
      for name, inner_value in outer_value :
      "${type}-${name}" => merge(
        {
          type = type,
          name = name,
        },
        inner_value
      )
    })
  ]...)
}
