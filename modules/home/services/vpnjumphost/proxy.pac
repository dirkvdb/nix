function FindProxyForURL(url, host) {
  var proxy_chain = "SOCKS5 127.0.0.1:1080; DIRECT";

  // Always-DIRECT domains (e.g. VPN portal): checked before dnsResolve so a
  // broken VPN DNS cannot force these through the proxy.
  // Always-DIRECT: byod.vito.be
  if (host === "byod.vito.be" || dnsDomainIs(host, ".byod.vito.be")) {
    return "DIRECT";
  }
  if (url.indexOf("byod.vito.be") !== -1) {
    return "DIRECT";
  }

  if (
    host === "vito.be" || dnsDomainIs(host, ".vito.be") ||
    host === "vito.local" || dnsDomainIs(host, ".vito.local") ||
    host === "int.vito.be" || dnsDomainIs(host, ".int.vito.be") ||
    host === "int.energyville.be" || dnsDomainIs(host, ".int.energyville.be")
  ) {
    return proxy_chain;
  }

  return "DIRECT";
}
