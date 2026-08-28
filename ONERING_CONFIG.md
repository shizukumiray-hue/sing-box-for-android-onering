# OneRing Configuration Guide

## What is OneRing?

OneRing is a bypass technique that helps evade ISP throttling by making your proxy connection appear as if it's connecting to a "bug" domain (typically a whitelisted or zero-rated domain) while actually routing traffic to your real proxy server via CDN Host header routing.

## How OneRing Works

```
┌─────────┐                  ┌─────────┐                  ┌──────────┐
│  Client │                  │   ISP   │                  │   CDN    │
│ (Phone) │                  │ Firewall│                  │(Cloudflare│
└────┬────┘                  └────┬────┘                  │ etc.)    │
     │                            │                       └────┬─────┘
     │  1. DNS: bug.domain.com    │                            │
     ├───────────────────────────>│                            │
     │  2. IP: 1.2.3.4            │                            │
     │<───────────────────────────┤                            │
     │                            │                            │
     │  3. TLS ClientHello        │                            │
     │     SNI: bug.domain.com    │                            │
     ├───────────────────────────>├───────────────────────────>│
     │                            │                            │
     │  4. HTTP Request           │                            │
     │     Host: real.domain.com  │                            │
     ├───────────────────────────>├───────────────────────────>│
     │                            │                            │
     │                            │         ┌──────────────────┤
     │                            │         │ 5. CDN routes    │
     │                            │         │    based on Host │
     │                            │         │    header        │
     │                            │         └──────────────────>│
     │                            │                            │
     │                            │                       ┌────▼─────┐
     │                            │                       │   Real   │
     │<──────────────────────────────────────────────────┤  Server  │
     │  6. Response from real server                     │          │
     │                                                    └──────────┘
```

**Result:** ISP sees connection to "bug.domain.com" (not throttled), but your traffic actually goes to "real.domain.com" via CDN routing.

## Configuration Format

In your sing-box outbound configuration, use this format in the `tls.server_name` field:

```
onering:real_domain:bug_domain
```

### Format Breakdown

- `onering:` - Prefix that activates OneRing mode
- `real_domain` - Your actual proxy server domain (where traffic is routed)
- `bug_domain` - The bug/whitelisted domain (what ISP sees)

### Examples

```
onering:my-proxy.cloudflare.com:www.telkomsel.com
onering:server.example.com:bug.operator.net
onering:cdn.myserver.net:whitelisted.domain.com
```

## Protocol Support

OneRing works with protocols that use TLS and HTTP transport:

### ✅ Supported Protocols

- **VLESS** + WebSocket
- **VLESS** + HTTPUpgrade  
- **VMess** + WebSocket
- **VMess** + HTTPUpgrade
- **Trojan** + HTTPUpgrade
- **Shadowsocks** with v2ray-plugin (WebSocket mode)

### ❌ Not Supported

- Plain TCP without HTTP transport
- gRPC transport (uses different mechanism)
- QUIC/HTTP3 (no TLS SNI)

## Configuration Examples

### Example 1: VLESS + WebSocket + OneRing

```json
{
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy-onering",
      "server": "104.21.50.25",
      "server_port": 443,
      "uuid": "your-uuid-here",
      "tls": {
        "enabled": true,
        "server_name": "onering:my-server.cloudflare.com:www.telkomsel.com",
        "insecure": false,
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        }
      },
      "transport": {
        "type": "ws",
        "path": "/vless-ws",
        "headers": {
          "Host": "my-server.cloudflare.com"
        }
      }
    }
  ]
}
```

**Key Points:**
- `server` should be the bug domain's IP or the bug domain itself
- `server_name` uses OneRing format
- `transport.headers.Host` should match the real domain

### Example 2: VMess + HTTPUpgrade + OneRing

```json
{
  "type": "vmess",
  "tag": "proxy-onering",
  "server": "www.telkomsel.com",
  "server_port": 443,
  "uuid": "your-uuid-here",
  "security": "auto",
  "tls": {
    "enabled": true,
    "server_name": "onering:real-cdn.cloudflare.com:www.telkomsel.com"
  },
  "transport": {
    "type": "httpupgrade",
    "path": "/vmess",
    "host": "real-cdn.cloudflare.com"
  }
}
```

### Example 3: Trojan + HTTPUpgrade + OneRing

```json
{
  "type": "trojan",
  "tag": "trojan-onering",
  "server": "bug.operator.net",
  "server_port": 443,
  "password": "your-password-here",
  "tls": {
    "enabled": true,
    "server_name": "onering:my-trojan.example.com:bug.operator.net",
    "alpn": ["h2", "http/1.1"]
  },
  "transport": {
    "type": "httpupgrade",
    "path": "/trojan",
    "host": "my-trojan.example.com"
  }
}
```

## Choosing Bug Domains

### Good Bug Domain Characteristics

1. **Zero-rated by ISP** - Domains that don't count toward data quota
2. **Whitelisted** - Domains that ISP doesn't throttle
3. **Behind CDN** - Must support Host header routing (Cloudflare, Fastly, etc.)
4. **Stable DNS** - Should resolve consistently

### Common Bug Domains (Examples)

**Indonesia:**
- `www.telkomsel.com`
- `www.indihome.co.id`
- `graph.facebook.com`
- `www.instagram.com`

**Other Regions:**
- Check your ISP's zero-rating programs
- Social media domains (often whitelisted)
- Government or educational domains
- CDN edge domains

### Testing Bug Domains

```bash
# Check if domain is behind CDN
dig +short bug.domain.com

# Test if Host header routing works
curl -H "Host: real-domain.com" https://bug.domain.com

# Check TLS/SNI support
openssl s_client -connect bug.domain.com:443 -servername bug.domain.com
```

## Server-Side Requirements

Your proxy server **must** be behind a CDN that supports Host header routing:

### Supported CDNs
- ✅ Cloudflare
- ✅ Fastly  
- ✅ Akamai
- ✅ AWS CloudFront
- ✅ Azure CDN

### Server Configuration

Your server should:
1. Accept connections from CDN IPs
2. Route based on HTTP Host header
3. Have valid TLS certificate for real domain
4. Support WebSocket or HTTPUpgrade

Example nginx config:
```nginx
server {
    listen 443 ssl http2;
    server_name my-server.cloudflare.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location /vless-ws {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Troubleshooting

### Connection Fails

**Symptom:** Cannot connect, timeout errors

**Solutions:**
1. Verify bug domain resolves: `dig +short bug.domain.com`
2. Check CDN routing: `curl -v -H "Host: real.com" https://bug.com`
3. Ensure server accepts CDN IPs (not blocking Cloudflare ranges)
4. Test without OneRing first (use real domain directly)

### Slow Connection

**Symptom:** Connection works but very slow

**Solutions:**
1. Bug domain might still be throttled - try different bug domain
2. CDN routing adds latency - this is normal, tradeoff for bypass
3. Check server load and bandwidth

### TLS/SSL Errors

**Symptom:** Certificate validation fails

**Solutions:**
1. Ensure `server_name` in TLS config matches OneRing format
2. Set `insecure: false` to validate real domain cert
3. Check server certificate is valid for real domain
4. Enable uTLS fingerprinting to avoid detection

### Host Header Mismatch

**Symptom:** Connection succeeds but server returns 404 or wrong content

**Solutions:**
1. Verify `transport.headers.Host` or `transport.host` matches real domain
2. Check server virtual host configuration
3. Ensure CDN passes Host header to origin

### ISP Still Throttles

**Symptom:** OneRing connects but still slow

**Solutions:**
1. Try different bug domains (yours might be detected)
2. Use uTLS fingerprinting: `"utls": {"enabled": true, "fingerprint": "chrome"}`
3. Rotate between multiple bug domains
4. Combine with other obfuscation (like changing ports)

## Testing Your Configuration

### Step 1: Test Without OneRing

```json
{
  "tls": {
    "server_name": "my-server.cloudflare.com"
  }
}
```

If this works, your server is configured correctly.

### Step 2: Enable OneRing

```json
{
  "tls": {
    "server_name": "onering:my-server.cloudflare.com:bug.domain.com"
  }
}
```

If this fails but step 1 worked, issue is with OneRing parsing or bug domain.

### Step 3: Verify with Logs

Enable debug logging in sing-box:
```json
{
  "log": {
    "level": "debug",
    "output": "/sdcard/singbox-debug.log"
  }
}
```

Look for:
```
[DEBUG] OneRing: parsed real=my-server.cloudflare.com bug=bug.domain.com
[DEBUG] OneRing: dialing to bug.domain.com
[DEBUG] OneRing: TLS SNI set to bug.domain.com  
[DEBUG] OneRing: HTTP Host set to my-server.cloudflare.com
```

## Implementation Details

OneRing is implemented in sing-box core at:
- `sing-box/common/onering/onering.go` - Parses OneRing format
- `sing-box/transport/v2rayhttp/client.go` - HTTP transport integration
- `sing-box/transport/v2raywebsocket/client.go` - WebSocket integration

The implementation:
1. Parses `onering:real:bug` from `server_name`
2. Overrides dial destination to bug domain
3. Sets TLS SNI to bug domain
4. Sets HTTP Host header to real domain
5. CDN routes request based on Host header

Test coverage: 90.3% (26 test cases)

## Security Considerations

### Privacy
- ISP sees connection to bug domain (metadata visible)
- Actual traffic is encrypted (content hidden)
- SNI is visible (that's the point - shows bug domain)

### Detection Risk
- OneRing technique is detectable if ISP inspects HTTP Host header
- Mitigate with uTLS fingerprinting and protocol obfuscation
- Rotate bug domains periodically

### Legality
- Check local laws regarding VPN/proxy usage
- Some ISPs explicitly prohibit bypassing throttling
- Use responsibly and at your own risk

## FAQ

**Q: Can I use any domain as bug domain?**  
A: No. Bug domain must be behind CDN that supports Host header routing, and ideally zero-rated or whitelisted by your ISP.

**Q: Does this work without CDN?**  
A: No. OneRing requires CDN to route requests based on HTTP Host header.

**Q: Will this bypass DPI (Deep Packet Inspection)?**  
A: Partially. It bypasses SNI-based filtering and quota systems, but sophisticated DPI can still detect it by inspecting Host header.

**Q: Can I use multiple bug domains?**  
A: Not in single config. But you can create multiple outbound configs with different bug domains and rotate/fallback between them.

**Q: What if my bug domain stops working?**  
A: Switch to different bug domain. ISPs can detect and throttle known bug domains over time.

## Additional Resources

- [sing-box Documentation](https://sing-box.sagernet.org/)
- [OneRing Implementation Source Code](../sing-box/common/onering/)
- [Build and Sign Guide](BUILD_AND_SIGN_GUIDE.md)

---

**Note:** This implementation is based on the OneRing technique commonly used in Indonesia and other regions with ISP throttling. Effectiveness varies by ISP and region.
