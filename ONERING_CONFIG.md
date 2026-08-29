# OneRing Configuration Guide

## What is OneRing?

OneRing is a bypass technique that allows you to evade ISP throttling by splitting the connection logic:

1. **TCP Connection**: Dial to a "bug" domain (unthrottled by ISP, e.g., `telkomsel.com`)
2. **TLS SNI**: Set Server Name Indication to the bug domain
3. **HTTP Host Header**: Set to the real destination domain (e.g., `cloudflare.com`)
4. **CDN Routing**: CDN routes the request based on Host header, not SNI

**Result**: ISP sees connection to "bug domain" → no throttling applied, but the CDN delivers content from the real domain.

---

## Configuration Format

OneRing uses a special format in the `server_name` field:

```
onering:<real_domain>:<bug_domain>
```

**Components**:
- `onering:` - Prefix that activates OneRing mode
- `<real_domain>` - Actual CDN/server domain (used in HTTP Host header)
- `<bug_domain>` - Bug domain for TCP connection (unthrottled by ISP)

---

## Supported Protocols

OneRing works with protocols that combine:
- TLS handshake (for SNI manipulation)
- HTTP upgrade or WebSocket (for Host header manipulation)

### ✅ Supported
- **VLESS** + WebSocket
- **VLESS** + HTTPUpgrade  
- **VMess** + WebSocket
- **VMess** + HTTPUpgrade
- **Trojan** + HTTPUpgrade
- **Shadowsocks** + v2ray-plugin (WebSocket mode)

### ❌ Not Supported
- Raw TCP (no TLS)
- QUIC-based transports (different bypass needed)
- gRPC (different header mechanism)
- Plain HTTP (no TLS SNI to manipulate)

---

## Configuration Examples

### 1. VLESS + WebSocket (Most Common)

```json
{
  "type": "vless",
  "tag": "vless-onering",
  "server": "1.2.3.4",
  "server_port": 443,
  "uuid": "your-uuid-here",
  "tls": {
    "enabled": true,
    "server_name": "onering:real.cloudflare.com:bug.telkomsel.com",
    "insecure": false
  },
  "transport": {
    "type": "ws",
    "path": "/websocket",
    "headers": {
      "Host": "real.cloudflare.com"
    }
  }
}
```

**What happens**:
1. TCP connects to `1.2.3.4:443`
2. TLS SNI = `bug.telkomsel.com` (ISP sees this)
3. HTTP Host = `real.cloudflare.com` (CDN routes by this)
4. WebSocket path = `/websocket`

---

### 2. VMess + HTTPUpgrade

```json
{
  "type": "vmess",
  "tag": "vmess-onering",
  "server": "1.2.3.4",
  "server_port": 443,
  "uuid": "your-uuid-here",
  "security": "auto",
  "alter_id": 0,
  "tls": {
    "enabled": true,
    "server_name": "onering:cdn.example.com:free.isp-domain.com"
  },
  "transport": {
    "type": "httpupgrade",
    "path": "/upgrade",
    "host": "cdn.example.com"
  }
}
```

---

### 3. Complete sing-box Configuration

```json
{
  "log": {
    "level": "info"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 1080
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "vless-onering",
      "server": "1.2.3.4",
      "server_port": 443,
      "uuid": "your-uuid-here",
      "flow": "",
      "tls": {
        "enabled": true,
        "server_name": "onering:real.cloudflare.com:bug.telkomsel.com",
        "insecure": false,
        "alpn": ["h2", "http/1.1"]
      },
      "transport": {
        "type": "ws",
        "path": "/websocket",
        "headers": {
          "Host": "real.cloudflare.com"
        }
      }
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "direct"
      }
    ],
    "final": "vless-onering"
  }
}
```

---

## Choosing Bug Domains

### Good Bug Domains (Indonesia Example)

**Telkomsel**:
- `telkomsel.com`
- `my.telkomsel.com`

**XL Axiata**:
- `xl.co.id`
- `my.xl.co.id`

**Criteria for bug domains**:
1. ✅ Owned by ISP or whitelisted
2. ✅ Supports HTTPS (CDN behind it)
3. ✅ Not rate-limited
4. ❌ Avoid government/banking domains

---

## Server-Side Requirements

Your server **must** be behind a CDN that routes by Host header:

### Cloudflare Setup Example

1. **DNS Record**:
   ```
   A   real.cloudflare.com   1.2.3.4   (Proxied)
   ```

2. **sing-box Server** (`config.json`):
   ```json
   {
     "inbounds": [
       {
         "type": "vless",
         "listen": "127.0.0.1",
         "listen_port": 8080,
         "users": [
           {
             "uuid": "your-uuid-here"
           }
         ],
         "transport": {
           "type": "ws",
           "path": "/websocket"
         }
       }
     ],
     "outbounds": [
       {
         "type": "direct"
       }
     ]
   }
   ```

---

## Troubleshooting

### Connection Fails

**Check**:
1. Server IP correct?
2. Port open (firewall)?
3. UUID/password correct?
4. Transport path matches server?

### OneRing Not Working (Still Throttled)

**Possible causes**:
1. Bug domain is not actually whitelisted
2. CDN not routing by Host header
3. Server not behind CDN

---

## Security Considerations

**Privacy**: ✅ Traffic is encrypted (TLS + protocol encryption)
- ISP sees: Connection to bug domain (encrypted)
- ISP cannot see: Real destination, content, Host header

**Risks**:
- ⚠️ Bug domain whitelisting can be revoked
- ⚠️ May violate ISP Terms of Service

---

## Testing Your Configuration

```bash
# Test connection
curl -x socks5://127.0.0.1:1080 https://www.google.com

# Check speed
curl -x socks5://127.0.0.1:1080 -o /dev/null https://speed.cloudflare.com/__down?bytes=10000000
```

---

## FAQ

**Q: Do I need to modify my server config?**
A: No, OneRing is client-side only. Server just needs to be behind CDN.

**Q: Can I use OneRing with direct IP (no domain)?**
A: No, you need a domain for TLS SNI and Host header manipulation.

**Q: Does OneRing work on all ISPs?**
A: No, only ISPs that whitelist certain domains. Test first.
