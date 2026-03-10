# Sichere Infrastruktur von Tag 1: VPN, Reverse Proxy und Networking in der Praxis

**Kategorie:** Networking & Security | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-02-21

**Excerpt:** NAS und Hetzner-Server standen -- aber wie verbinde ich sie sicher miteinander? Erst WireGuard, dann Tailscale. Erst Nginx, dann Traefik. Viel ausprobiert, vieles verworfen, dabei mehr Networking gelernt als jedes Tutorial vermittelt.

---

## Die zentrale Frage: Wie wird das produktionsreif?

NAS läuft, Hetzner-Server läuft, erste Services sind deployed. Aber jetzt stellt sich die praktische Frage: Wie kommunizieren diese Systeme sicher miteinander? Wie komme ich von unterwegs auf meine Dienste? Und wie mache ich Services erreichbar, die erreichbar sein sollen -- ohne alles offen ins Internet zu stellen?

Das waren Fragen, die ich zu dem Zeitpunkt nicht theoretisch beantworten konnte. Ich musste es praktisch ausprobieren.

---

## WireGuard: Theorie gut, Praxis fragil

Mein erster Gedanke war WireGuard -- ein modernes VPN-Protokoll, das in meiner Recherche immer wieder als schnelle und sichere Lösung aufkam. Die Idee: einen verschlüsselten Tunnel zwischen NAS und Server aufbauen, damit ich von überall sicher auf meine Dienste zugreifen kann.

In der Praxis bin ich damit auf der Synology NAS nicht weit gekommen. WireGuard ist dort nicht nativ im VPN-Server-Paket enthalten. Was es gibt, sind Drittanbieter-Pakete und Docker-basierte Lösungen -- aber die sind fragil. DSM-Updates können das Kernel-Modul brechen, die Installation ist abhängig von der Hardware-Architektur, und insgesamt war das eine ziemlich frickelige Angelegenheit. Ich habe einige Zeit damit verbracht und keine stabile Lösung hinbekommen.

---

## Tailscale: Das richtige Tool für den Job

Bei der weiteren Recherche bin ich auf Tailscale gestoßen. Tailscale basiert auf WireGuard und nutzt das gleiche Protokoll für die Verschlüsselung. Der entscheidende Unterschied: Tailscale ist nativ im Synology-Paketzentrum verfügbar. Kein Drittanbieter-Paket, kein Docker-Workaround, keine Angst vor dem nächsten DSM-Update.

Installation auf der NAS, auf dem Server, auf meinem MacBook -- und plötzlich waren alle Geräte im gleichen verschlüsselten Netzwerk. Ich konnte von unterwegs auf meine NAS zugreifen, ohne einen einzigen Port zu öffnen. Der Server und die NAS konnten sicher miteinander kommunizieren.

Das war der Moment, in dem ich verstanden habe: Manchmal ist die Lösung nicht, sich durch eine komplizierte Einrichtung zu kämpfen, sondern das richtige Tool für den Job zu finden. WireGuard ist ein großartiges Protokoll -- aber Tailscale hat es für mein Setup erst praktisch nutzbar gemacht.

---

## Reverse Proxy: Von IP:Port zu Subdomains

Mit Tailscale war die interne Kommunikation gelöst. Aber manche Services auf dem Hetzner-Server sollten auch öffentlich erreichbar sein -- n8n, das agra-dashboard, später Grafana. Nicht über IP-Adresse und Portnummer, sondern über saubere Subdomains mit HTTPS.

Reverse Proxies waren für mich zu diesem Zeitpunkt komplettes Neuland. Mein erster Ansatz war Nginx Proxy Manager -- eine grafische Oberfläche, in der man Proxy-Hosts anlegt, SSL-Zertifikate verwaltet und Traffic weiterleitet. Das hat funktioniert und mir erstmal gezeigt, was ein Reverse Proxy überhaupt tut.

Nach weiterer Recherche und einer Empfehlung bin ich dann auf Traefik gestoßen. Ein anderer Ansatz: Statt grafischer Oberfläche wird alles über Labels in der Docker-Compose-Konfiguration gesteuert. Traefik erkennt Container automatisch und kümmert sich selbstständig um Let's-Encrypt-Zertifikate.

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.n8n.rule=Host(`n8n.meinedomain.tech`)"
  - "traefik.http.routers.n8n.tls.certresolver=le"
```

Services über Subdomains erreichbar, mit gültigen Zertifikaten -- das Grundprinzip war verstanden.

---

## Networking lernt man durch Debugging

Das klingt im Rückblick alles strukturiert. War es nicht. Ich war ungeduldig, wollte Ergebnisse sehen, habe Dinge eingerichtet, die nicht beim ersten Mal funktioniert haben -- und habe dabei mehr über Networking gelernt, als ich erwartet hätte.

DNS-Einträge, SSL-Zertifikate, wie Subdomains funktionieren, was ein Reverse Proxy eigentlich tut -- das alles waren keine abstrakten Konzepte mehr, sondern Dinge, die ich anfassen und testen konnte.

Wenn ein Service nicht erreichbar war, musste ich debuggen: Liegt es am DNS? Am Zertifikat? Am Routing? An der Firewall? Dieses Troubleshooting hat mir mehr beigebracht als jede Networking-Theorie.

---

## Die Architektur, die sich ergeben hat

Durch das Ausprobieren hat sich Stück für Stück eine Architektur entwickelt:

- **Tailscale** als VPN-Schicht für die interne Kommunikation zwischen allen Systemen
- **Reverse Proxy** für Services, die öffentlich erreichbar sein sollen
- **Klare Trennung**: Interner Traffic läuft über das VPN, externer Traffic über den Reverse Proxy

Das war kein Masterplan, den ich am Anfang auf ein Whiteboard gezeichnet habe. Es war das Ergebnis von viel Ausprobieren, einigen Sackgassen und der Bereitschaft, Lösungen wieder zu verwerfen, wenn es eine bessere gibt.

---

## Lernen durch Sackgassen

Diese Phase hat mir gezeigt, dass Networking eines dieser Themen ist, die man nur durch praktisches Arbeiten wirklich versteht. Die Theorie gibt dir die Begriffe. Die Praxis gibt dir das Verständnis.

WireGuard hat nicht funktioniert -- also Tailscale.  
Nginx war ein guter Start -- Traefik ein weiterer Schritt.

Das ist kein Scheitern. Das ist Lernen.

---

**Nächster Post:**
Sandbox kaputt, alles weg -- wie ich Terraform lieben gelernt habe.
