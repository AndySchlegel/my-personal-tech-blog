
# Blackbox kaputt: Vom Provider-Router zum eigenen Netzwerk

**Kategorie:** Homelab & Self-Hosting | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-02-19

**Excerpt:** NAS bestellt, Hetzner-Server lief schon — aber der Telekom-Router ließ sich kaum konfigurieren. Das war der Punkt, an dem ich mein eigenes Netzwerk aufgebaut habe. Wie aus den Limitierungen eines Consumer-Routers Schritt für Schritt ein vollwertiges Homelab entstanden ist.

---

## Am Limit des Provider-Routers

Zu diesem Zeitpunkt liefen bereits zwei zentrale Bausteine meiner Infrastruktur: ein Cloud-Server bei Hetzner und eine frisch eingerichtete Synology NAS. Zwei Systeme, die miteinander kommunizieren sollten — und ein Heimnetzwerk, das dafür plötzlich deutlich flexibler sein musste.

Der Telekom-Router war dafür allerdings kaum geeignet. Ein geschlossenes System mit stark eingeschränkten Konfigurationsmöglichkeiten. Für normale Internetnutzung vollkommen ausreichend — aber sobald mehrere Systeme miteinander sprechen sollen, stößt man schnell an Grenzen.

Genau dieser Moment wurde zum Wendepunkt. Statt mich weiter innerhalb dieser Limits zu bewegen, fiel die Entscheidung: Wenn ich Infrastruktur verstehen will, dann auch das Netzwerk dahinter.

---

## UniFi: Mein Netzwerk, meine Regeln

Die Wahl fiel auf Ubiquiti UniFi — Cloud Gateway Fiber, Access Point, Modem. Enterprise-Hardware, die in professionellen Umgebungen eingesetzt wird.

Der Unterschied war sofort spürbar. Plötzlich ließ sich das Netzwerk wirklich gestalten: Firewall-Regeln definieren, VLANs strukturieren, Traffic analysieren und nachvollziehen, wie Geräte miteinander kommunizieren.

Damit begann ein völlig neues Lernfeld. Subnetting, DNS, DHCP, Firewall-Regeln — alles Themen, die auf dem Papier relativ schnell verstanden sind. Ein eigenes Netzwerk zu entwerfen, in dem mehrere Systeme stabil miteinander arbeiten, ist jedoch eine ganz andere Erfahrung.

Viele Dinge funktionieren erst nach mehreren Iterationen. Regeln greifen nicht wie erwartet, Services finden sich nicht im Netzwerk, Ports sind falsch gesetzt. Genau diese Momente sind es aber, in denen Infrastruktur wirklich verständlich wird.

---

## Mehr als nur Storage

Die NAS war von Anfang an als Infrastruktur-Plattform gedacht — ein System, auf dem ich Container und Docker vertiefen kann, nicht nur Storage.

Container liefen dort dauerhaft, Backups wurden organisiert, Services zusammengeführt. Gleichzeitig wurde die NAS zum Ort, an dem ich ausprobieren konnte, wie sich Infrastruktur betreiben lässt: Updates, Monitoring, Netzwerkregeln, Zugriffskontrollen.

Mit NAS, Cloud-Server und dem neuen Netzwerk entstand nach und nach eine Umgebung, die deutlich mehr war als nur ein einzelner Server.

---

## Wenn Bausteine zusammenspielen

Je mehr Systeme dazu kamen, desto wichtiger wurde Übersicht.

Prometheus begann Metriken zu sammeln, Grafana visualisierte die Systeme, Dashy wurde zur zentralen Startseite für die Infrastruktur. Zum ersten Mal entstand ein Gefühl dafür, wie mehrere Services zusammen ein funktionierendes Gesamtsystem bilden.

Was zunächst als kleines Setup begann, entwickelte sich langsam zu einer Infrastruktur, die beobachtet, gepflegt und automatisiert werden musste.

---

## Automatisieren statt wiederholen

Mit wachsender Infrastruktur tauchten schnell Aufgaben auf, die sich ständig wiederholten. Statusmeldungen, kleine Datenbewegungen zwischen Systemen, Benachrichtigungen.

Hier kam n8n ins Spiel. Workflows auf der NAS verbanden Dienste miteinander, automatisierten Abläufe und nahmen viele kleine manuelle Schritte ab.

Ein weiterer Baustein in einer Umgebung, die immer stärker zusammenwuchs.

---

## Cloud nutzen, Homelab verantworten

Rückblickend war der Aufbau des Homelabs einer der wichtigsten Schritte dieser Phase.

In der Cloud lernt man, Services zu nutzen.  
Im Homelab lernt man, Infrastruktur zu betreiben.

Genau diese Kombination hat den weiteren Weg geprägt.

---

**Nächster Post:**  
Sichere Infrastruktur von Tag 1: VPN, Reverse Proxy und Networking in der Praxis
