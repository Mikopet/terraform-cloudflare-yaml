# terraform-cloudflare-yaml

This `terraform` module aims to help configure DNS records for cloudflare much easier,
via YAML files. Also the module tries to be as simple as it is possible.

Plese keep try testing, and give feedback.
The project is far from complete, I have done only the features I need for generic
configuration and for DNS settings for `migadu`.
Majority of the record types I believe should work as expected.

## Usage

Perhaps the most simplistic configuration is something like this:

```hcl
data "cloudflare_zone" "zone" {
  filter = {
    name = "example.com"
  }
}

module "cf_records" {
  source = "mikopet/yaml/cloudflare"

  zone_id = data.cloudflare_zone.zone.zone_id
  records = yamldecode(<<-YAML
A:
  example.com:
    value: 127.0.0.1
YAML
)
```
> [!NOTE]
> **At the time of writing the cloudflare documentation is incorrect!**  
> The currently working attribute is presented above: `.zone_id`.

But obviously the point of this module is to have a lot of configuration for records,
and not having them in HCL. While HCL is okay for lots of things, it's inconvinient
for these record data.

So let's speak about the YAML format a little bit more. If you make it this way:

```yaml
defaults: &defaults
  # TTL must be between 60 and 86400 seconds, or 1 for Automatic
  ttl: 3600
  proxied: false
  comment: 'via terraform'
  tags:
    - &dt 'tf'
records:
  CNAME:
    "@": # this is allowed in CF because of CNAME flattening
      <<: *defaults
      value: 'github.io'
      tags: [*dt, 'web']
      comment: 'main website'
      proxied: true
      ttl: 1 # when you use proxied, ttl must be `1`
    subdomain:
      <<: *defaults
      value: 'terraform.io'
```

And pass it this way:

```hcl
# ...
  records = yamldecode(file("${path.module}/records.yaml")).records
# ...
```

The result will be in HCL (inside the module):

```hcl
{
  "CNAME-@" = {
    comment         = "main website"
    name            = "@"
    proxied         = true
    tags            = [
      "tf",
      "web",
    ]
    ttl             = 1
    type            = "CNAME"
    value           = "github.io"
  }
  CNAME-subdomain = {
    comment         = "via terraform"
    name            = "subdomain"
    proxied         = false
    tags            = ["tf"]
    ttl             = 3600
    type            = "CNAME"
    value           = "terraform.io"
  }
}
```

...and will create two records:
```DNS Zone
;; CNAME Records
example.com.              1       IN      CNAME   github.io.    ; main website
subdomain.example.com.    3600    IN      CNAME   terraform.io. ; via terraform
```

Easy, right? Well, at least very compact!

As you see, the overrides working pretty well. However, there is an issue
with them. While YAML saves you to create the same name key for CNAMEs,
not every record type has this constraint. MX and TXT records for example
definitely should have the ability to put multiple records on the same name.

Therefore, you could do this (and it is the recommended way, so you name the terraform resources too):

```yaml
records:
  MX:
    migadu-1:
      name: '@'
      value: 'aspmx1.migadu.com'
      priority: 10
    migadu-2:
      name: '@'
      value: 'aspmx2.migadu.com'
      priority: 20
```

This will just simply create the following HCL:
```hcl
{
  MX-migadu-1 = {
    name     = "@"
    priority = 10
    type     = "MX"
    value    = "aspmx1.migadu.com"
  }
  MX-migadu-2 = {
    name     = "@"
    priority = 20
    type     = "MX"
    value    = "aspmx2.migadu.com"
  }
}
```

> [!NOTE]
> TODO: it would be nice, if the snippet above could be generated with some sequence, using `range()` perhaps.

## More tricks

At this point you probably have your brain open, how easy some things could be from now on.
Yet, there are more fun:

```hcl
locals {
  dns_config = templatefile(
    "${path.module}/config/dns.yaml",
    {
      domain = var.apex_domain
    }
  )
}

module "cf_records" {
  # ...
  records = yamldecode(local.dns_config).records
}
```

and the YAML for this:

```yaml
records:
  CNAME:
    key1._domainkey:
      value: 'key1.${domain}._domainkey.migadu.com.'
      tags: ['tf', 'mail', 'migadu', 'dkim']
      comment: 'DKIM primary key'
    key2._domainkey:
      value: 'key2.${domain}._domainkey.migadu.com.'
      tags: ['tf', 'mail', 'migadu', 'dkim']
      comment: 'DKIM secondary key'
    key3._domainkey:
      value: 'key3.${domain}._domainkey.migadu.com.'
      tags: ['tf', 'mail', 'migadu', 'dkim']
      comment: 'DKIM tertiary key'
```

And voila, you are easily done!

In case if you want to debug what is happening inside the module:

```hcl
output "debug" {
  value = module.cf_records.debug
}
```

## Troubleshoot

The module itself is not fitted for reporting errors, so any error you encounter
is most probably coming from Cloudflare.

One of the problems could be that you don't have premium subscription to use tags.
Remove tag definitions.

### Migrating from v4 to v5

Fortunately (for you) I've suffered through the failures to present you a working solution.

#### Preparation
You must update your code as the [migration guide] suggests.
If you were getting the zone ID with data resource, the syntax changed to:
```terraform
data "cloudflare_zone" "zone" {
  filter = {
    name = "example.com"
  }
}
```

> [!NOTE]
> **At the time of writing the cloudflare documentation is incorrect!**  
> Where you are referencing this data resource, the evidently correct way may be not `.id` but `.zone_id`!

If you were also using `allow_overwrite`, remove that too.

#### The Hard Part
Cloudflare suggests, that you should update to the latest v4, before upgrading to v5.
I did that to no avail, even with refreshed state I encountered many errors.

But at this point you should not see more errors than this one type:
```
Error: no schema available for module.cf_records.cloudflare_record.record["CNAME-www"] while reading state; this is a bug in Terraform and should be reported
```

The only way I was able to solve this without outage, is to remove the problematic resources from the state
(including all related cloudflare resources listed at once):
```bash
$ terraform state rm data.cloudflare_zone.zone module.cf_records
```

And apply the new code.
> [!WARNING]
> For actually be able to successfully run the apply plan, you have to delete all related records first!

> [!TIP]
> As the migration guide suggests, you may skip the reprovision with `import` statements.  
> I did not try that, as getting the IDs of the records seemed troublesonme...
> but if minor DNS downtime is unacceptable for you... you may try it!

## Contribute

Just open issues or PRs if you feel like that.

