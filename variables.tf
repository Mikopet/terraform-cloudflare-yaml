variable "zone_id" {
  description = "The ID of the Zone to put the records in"
  type        = string
}

variable "records" {
  description = "The DNS record definitions grouped by record type"
  # TODO: exhaustive type definition
  # type = map(map(object({
  #   name            = optional(string)
  #   ttl             = optional(number)
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

  # TODO: validation for conflicting `data` and `content` attributes
}
