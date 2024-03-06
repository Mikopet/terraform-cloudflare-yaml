variable "zone_id" {
  description = "Zone ID for the zone to put records in"
  type        = string
}

variable "records" {
  description = "the DNS records grouped by record type"
  # TODO: exhaustive type definition
  # type = map(map(object({
  #   name            = optional(string)
  #   ttl             = optional(number)
  #   allow_overwrite = optional(bool)
  #   proxied         = optional(bool)
  #   value           = optional(string)
  #   priority        = optional(number)
  #   comment         = optional(string)
  #   data = optional(object({
  #     service  = string
  #     proto    = string
  #     name     = string
  #     priority = number
  #     weight   = number
  #     port     = number
  #     target   = string
  #   }))
  # })))

  validation {
    error_message = "`records` should be in [A, AAAA, CAA, CNAME, TXT, SRV, LOC, MX, NS, SPF, CERT, DNSKEY, DS, NAPTR, SMIMEA, SSHFP, TLSA, URI, PTR, HTTPS, SVCB]"
    condition = 0 == length(setsubtract(
      keys(var.records),
      [
        "A",
        "AAAA",
        "CAA",
        "CNAME",
        "TXT",
        "SRV",
        "LOC",
        "MX",
        "NS",
        "SPF",
        "CERT",
        "DNSKEY",
        "DS",
        "NAPTR",
        "SMIMEA",
        "SSHFP",
        "TLSA",
        "URI",
        "PTR",
        "HTTPS",
        "SVCB",
      ]
    ))
  }

  # validation: if it has no `value` attr, data block must present. vice versa.
}
