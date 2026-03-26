---
name: dns-infrastructure-attacks
description: DNS-level attacks affecting web applications — subdomain takeover, dangling DNS records, DNS rebinding for SSRF bypass, and domain security configuration. Use when auditing DNS configuration, reviewing domain setup for new products/services, decommissioning services (the most dangerous time for dangling DNS), or reviewing infrastructure that uses multiple subdomains, CDNs, or cloud services. Covers subdomain takeover via Vercel/Heroku/GitHub Pages/S3 dangling CNAMEs, DNS rebinding to bypass SSRF protections, DNSSEC, CAA records, SPF/DKIM/DMARC for email spoofing prevention, and domain hygiene.
---

# DNS & Infrastructure Attacks

## Attack 1: Subdomain Takeover

### What It Is
A DNS record (CNAME, A) points to a service that no longer exists. An attacker claims that service and now controls content on YOUR subdomain.

```
Your DNS:  staging.yourapp.com → CNAME → your-old-project.vercel.app
Reality:   your-old-project was deleted from Vercel
Attack:    Attacker creates their project at your-old-project.vercel.app
Result:    staging.yourapp.com now serves ATTACKER'S content
```

### Why It's Critical
- **Cookie theft**: Cookies scoped to `.yourapp.com` are sent to the attacker's page
- **Phishing**: Attacker serves login page on your legitimate subdomain
- **CSP bypass**: If your CSP trusts `*.yourapp.com`, attacker bypasses it
- **Email abuse**: SPF records may authorize the subdomain to send email

### Vulnerable Services (Common Providers)

| Service | Indicator of Vulnerability | CNAME Target |
|---------|--------------------------|--------------|
| **Vercel** | Returns 404 project not found | `*.vercel.app` |
| **Heroku** | "No such app" page | `*.herokuapp.com` |
| **GitHub Pages** | 404 | `*.github.io` |
| **AWS S3** | NoSuchBucket | `*.s3.amazonaws.com` |
| **AWS CloudFront** | Bad request | `*.cloudfront.net` |
| **Netlify** | "Not found" page | `*.netlify.app` |
| **Surge.sh** | "project not found" | `*.surge.sh` |
| **Shopify** | "Sorry, this shop is currently unavailable" | `*.myshopify.com` |
| **Azure** | NXDOMAIN | `*.azurewebsites.net` |

### Detection
```bash
# List all DNS records for your domain
dig yourapp.com ANY +short
dig staging.yourapp.com CNAME +short

# Check all subdomains (use subdomain enumeration)
# For each CNAME, verify the target still exists

# Quick check: does the CNAME target resolve?
host your-old-project.vercel.app
# If NXDOMAIN or service-specific error → VULNERABLE

# Automated: use subjack, nuclei, or manual checks
for sub in $(cat subdomains.txt); do
  cname=$(dig +short CNAME $sub)
  if [ -n "$cname" ]; then
    echo "$sub → $cname"
    # Check if target responds correctly
    curl -s -o /dev/null -w "%{http_code}" "https://$sub" 
  fi
done
```

### Prevention
1. **When decommissioning a service**: Remove DNS records FIRST, then delete the service
2. **Regular audit**: Monthly check all subdomains for dangling records
3. **Use CNAME validation**: Vercel and some providers verify domain ownership before claiming
4. **Minimize subdomains**: Fewer subdomains = smaller attack surface

### Immediate Fix for Dangling Records
```bash
# Delete the dangling CNAME record from your DNS provider
# If you can't delete immediately, point it to a page you control
```

## Attack 2: DNS Rebinding (SSRF Bypass)

### What It Is
DNS rebinding bypasses IP-based SSRF protections:
1. Application validates URL → resolves `evil.com` to `93.184.216.34` (external, passes check)
2. Application fetches URL → resolves `evil.com` to `127.0.0.1` (internal, bypasses check)

DNS resolves to different IPs on different queries. The validation and the fetch get different answers.

### How It Works
```
Time 0: Application validates evil.com
  DNS query → evil.com = 93.184.216.34 (external IP)
  Validation passes ✓

Time 1: Application fetches evil.com (seconds later)
  DNS query → evil.com = 127.0.0.1 (or 169.254.169.254)
  Fetch hits internal service! ✗
```

Attacker controls DNS with very low TTL (1 second), alternating between external and internal IPs.

### Defense
```typescript
// Resolve DNS ONCE and pin the IP for the entire operation
import dns from 'dns/promises'

async function safeFetchWithDNSPin(url: string): Promise<Response> {
  const parsed = new URL(url)
  
  // Resolve DNS once
  const addresses = await dns.resolve4(parsed.hostname)
  const ip = addresses[0]
  
  // Validate the resolved IP (not the hostname)
  if (isInternalIP(ip)) throw new Error('Internal IP blocked')
  
  // Fetch using the RESOLVED IP (bypass further DNS resolution)
  const response = await fetch(url, {
    headers: { Host: parsed.hostname },  // Keep original Host header
    // Some fetch implementations need custom DNS resolver or agent
  })
  return response
}
```

## Attack 3: Email Spoofing via Missing Records

### SPF (Sender Policy Framework)
Without SPF, anyone can send email as `@yourapp.com`:
```dns
; Add to your DNS:
yourapp.com.  IN  TXT  "v=spf1 include:_spf.google.com include:sendgrid.net -all"
; -all = reject email from unauthorized servers
```

### DKIM (DomainKeys Identified Mail)
```dns
; Add DKIM public key to DNS (your email provider gives you this)
selector._domainkey.yourapp.com.  IN  TXT  "v=DKIM1; k=rsa; p=MIIBIj..."
```

### DMARC (Domain-based Message Authentication)
```dns
; Combines SPF + DKIM with policy enforcement
_dmarc.yourapp.com.  IN  TXT  "v=DMARC1; p=reject; rua=mailto:dmarc@yourapp.com"
; p=reject = reject email that fails both SPF and DKIM
```

### Why This Matters
Without these records, an attacker can send emails from `support@yourapp.com` to your customers → phishing → credential theft.

## Attack 4: DNS as Information Source

### What DNS Reveals
```bash
# Enumerate subdomains (reveals infrastructure)
dig yourapp.com ANY
dig _acme-challenge.yourapp.com TXT  # Let's Encrypt challenge = active cert
dig _dmarc.yourapp.com TXT  # Email configuration
dig mail.yourapp.com MX  # Email provider

# Zone transfer attempt (misconfigured DNS servers)
dig @ns1.yourapp.com yourapp.com AXFR
# If this returns all records → your DNS is misconfigured
```

### Prevention
- Disable zone transfers to unauthorized servers
- Use DNS providers that prevent zone transfer by default
- Be aware that subdomain enumeration is always possible via brute-force

## Domain Security Configuration

### CAA Records (Certificate Authority Authorization)
```dns
; Only these CAs can issue certificates for your domain
yourapp.com.  IN  CAA  0 issue "letsencrypt.org"
yourapp.com.  IN  CAA  0 issue "sectigo.com"
yourapp.com.  IN  CAA  0 iodef "mailto:security@yourapp.com"
```

Without CAA records, any CA can issue a certificate for your domain. With them, only authorized CAs can.

### DNSSEC
DNSSEC cryptographically signs DNS records, preventing DNS spoofing/poisoning. Enable via your DNS provider if supported.

## Infrastructure Audit Checklist

### Subdomain Hygiene
- [ ] All subdomains inventoried and documented
- [ ] Monthly check for dangling CNAME/A records
- [ ] Decommissioning process: delete DNS BEFORE deleting service
- [ ] Wildcard CNAME (`*.yourapp.com`) avoided unless necessary
- [ ] Unused subdomains removed

### Email Security
- [ ] SPF record configured with `-all` (hard fail)
- [ ] DKIM configured for all sending services
- [ ] DMARC configured with `p=reject`
- [ ] Regular DMARC reports reviewed

### Certificate Security
- [ ] CAA records limit certificate issuance to known CAs
- [ ] Certificates monitored via Certificate Transparency logs
- [ ] HSTS configured (forces HTTPS, prevents downgrade)

### DNS Hardening
- [ ] Zone transfers disabled for unauthorized servers
- [ ] DNSSEC enabled if supported by DNS provider
- [ ] DNS provider uses anycast for DDoS resilience
- [ ] Low TTL only on records that need frequent changes

## References

For SSRF bypass via DNS rebinding, see `ssrf-exploitation` skill.
For domain-related attack chains, see `exploit-chain-construction` skill.
