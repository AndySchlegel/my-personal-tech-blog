# Monitoring und Security: Warum ich früh angefangen habe und es sich ausgezahlt hat

**Kategorie:** Networking & Security | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-03-03

**Excerpt:** Prometheus und Grafana liefen schon auf meinem ersten Server. Was als einfaches Ressourcen-Monitoring begann, ist Stück für Stück zu einem mehrstufigen System gewachsen — Uptime Kuma für Verfügbarkeit, Wazuh als SIEM für Security-Events, Telegram als zentraler Alarmkanal. Jede Erweiterung hatte einen konkreten Grund.

---

## Prometheus/Grafana: Die ersten Metriken

Auf meinem ersten kleinen Hetzner-Server habe ich Prometheus und Grafana aufgesetzt. Basis-Metriken: CPU, RAM, Festplatte. Dazu ein Link ins Dashy-Dashboard, damit ich das Grafana-Panel schnell erreiche. Mehr nicht.

Das war kein durchdachter Monitoring-Plan. Es war Neugier: Ich wollte sehen, was auf dem Server passiert. Rückblickend war genau diese Neugier der Anfang von allem, was danach kam — weil sie eine Grundlage geschaffen hat, auf der ich immer weiter aufbauen konnte.

---

## Zentralisieren und erweitern

Mit dem zweiten Server und einer wachsenden Zahl von Services wurde klar: Basis-Metriken auf einem einzelnen Server reichen nicht mehr. Die NAS hatte zwar über DSM eigene Grundwerte, aber ich wollte alles an einem Ort sehen — und vor allem Alerting einrichten, damit ich nicht ständig manuell nachschauen muss.

Also habe ich Prometheus auf die NAS verlegt und als zentrale Sammelstelle eingerichtet. Node Exporter auf jedem Server für Systemmetriken, cAdvisor für Container-Metriken, Custom Exporter für service-spezifische Daten. Alles über Tailscale, alles verschlüsselt. 16 Targets, die alle 15 Sekunden gescraped werden.

Grafana hat drei Dashboards bekommen: eins pro Server mit Detailmetriken und ein Multi-Server-Overview für den schnellen Blick auf alles. CPU, RAM, Disk, I/O und Netzwerk — auf einen Blick, für alle Standorte. Alerts gehen direkt über Telegram: CPU über 90 %, RAM über 90 %, Disk über 80 % oder wenn ein Service nicht mehr erreichbar ist.

Gleichzeitig kamen Uptime Kuma und Portainer dazu. Uptime Kuma überwacht 12 Services im 60‑Sekunden‑Takt — per HTTP‑Check, TCP‑Check oder Ping. Das ergänzt genau die Perspektive, die Prometheus nicht abdeckt: Ist der Service aus Nutzersicht erreichbar? Auch hier gehen Alerts direkt auf Telegram.

---

## Bestätigung durch den Ernstfall

Dass sich dieses Setup bewährt, habe ich relativ früh erfahren. Einmal nachts unterwegs, mit einem Laptop, der nicht auf mein gewohntes Setup abgestimmt war — weil ich alles ursprünglich über mein anderes MacBook konfiguriert hatte.

Die Telegram-Benachrichtigungen haben mich sofort erreicht, und ich konnte das Problem remote eingrenzen und entschärfen.

Das war kein Worst-Case-Szenario. Es war der Moment, der bestätigt hat: Monitoring und Alerting funktionieren genau so, wie sie sollen — auch wenn die Umstände nicht ideal sind.

Was danach folgte, war keine Panikreaktion, sondern eine bewusste Weiterentwicklung. Der betroffene Server wurde komplett neu aufgesetzt, und dabei habe ich das Security-Setup deutlich verschärft:

- Docker-Daemon auf `127.0.0.1` gebunden, damit Container nicht versehentlich auf öffentlichen IPs lauschen  
- UFW-Firewall aktiviert, nur die Ports offen, die wirklich benötigt werden  
- fail2ban für SSH-Schutz mit automatischem Ban nach drei Fehlversuchen  
- Alle internen Services ausschließlich über Tailscale erreichbar

Dazu kam die proaktive Seite: Watchtower aktualisiert Docker-Container automatisch zu festen Zeiten. Auf den Servern laufen Unattended-Upgrades für Kernel- und Security-Patches, inklusive automatischer Reboots. Jeden Tag kommt eine Telegram-Benachrichtigung, dass die Updates sauber durchgelaufen sind.

Kein manuelles Patchen, kein Vergessen — alles automatisiert.

Security ist kein Zustand, den man einmal herstellt. Es ist ein Prozess, der sich mit jeder Erfahrung weiterentwickelt.

---

## Wazuh: Die Security-Lücke schließen

Prometheus und Uptime Kuma überwachen Performance und Verfügbarkeit. Aber Security-Events — wer greift auf was zu, welche Container starten mit welchen Rechten oder ob jemand versucht, sich per SSH einzuloggen — decken sie nicht ab.

Durch Recherche und Austausch mit anderen Engineers bin ich auf Wazuh gestoßen — ein Open-Source-SIEM, das genau diese Lücke schließt.

Also habe ich Wazuh auf der NAS aufgesetzt: Manager, Indexer und Dashboard. Auf beiden Cloud-Servern laufen Agents, die Events an den Manager melden. Docker-Listener überwachen Container-Aktivitäten in Echtzeit: `docker exec`-Befehle, Container mit Host-Netzwerk, Zugriffe auf den Docker-Socket oder privilegierte Container.

Die Events werden nach Severity klassifiziert. Alles ab Level 10 — also potenziell sicherheitsrelevant — wird direkt als Alert auf Telegram geschickt. Darunter wird lediglich geloggt. Das verhindert Alert-Fatigue: Ich werde nur gestört, wenn es wirklich relevant ist.

---

## Alle Wege führen zu Telegram

Über die Zeit hat sich ein dreistufiges Alerting-System entwickelt. Drei verschiedene Tools überwachen unterschiedliche Aspekte der Infrastruktur — und alle Alerts landen im gleichen Kanal:

**Grafana** für Performance: CPU, RAM, Disk, Netzwerk. Die Metriken, die zeigen, ob die Infrastruktur unter Last steht.

**Uptime Kuma** für Verfügbarkeit: Services antworten nicht mehr, Latenzen steigen oder Zertifikate laufen ab. Die Nutzerperspektive.

**Wazuh** für Security: Fehlgeschlagene SSH-Logins, verdächtige Container-Aktivitäten oder Dateiänderungen in kritischen Verzeichnissen.

Alle drei melden an Telegram. Egal ob ich zuhause am Schreibtisch sitze oder unterwegs bin — ich sehe sofort, was passiert und kann einschätzen, ob ich reagieren muss.

---

## Stück für Stück, nicht alles auf einmal

Ich möchte nicht den Eindruck erwecken, dass dieses Setup von Anfang an geplant war. Es war ein Prozess.

Erst Prometheus und Grafana, weil ich sehen wollte, was auf meinem Server passiert. Dann Uptime Kuma, weil Metriken allein nicht zeigen, ob ein Service wirklich erreichbar ist. Dann die Bestätigung, dass Alerting funktioniert — und die Erkenntnis, dass Performance-Monitoring allein nicht reicht. Und schließlich Wazuh, weil Security eine eigene Überwachungsebene braucht.

Jede Erweiterung hatte einen konkreten Auslöser. Dieses Setup ist nicht aus einem Tutorial entstanden, sondern aus echten Anforderungen im Betrieb.

---

## Früh anfangen zahlt sich aus

Monitoring ist nicht optional. Es ist die Grundlage dafür, zu verstehen, was in der eigenen Infrastruktur passiert — und rechtzeitig reagieren zu können, wenn etwas nicht stimmt.

Früh anfangen zahlt sich aus. Nicht weil man von Anfang an alles perfekt macht, sondern weil man eine Grundlage schafft, auf der man weiter aufbauen kann.

Mein erstes Grafana-Dashboard hatte drei Panels. Heute überwache ich damit drei Standorte. Der Unterschied ist nicht das Tool — der Unterschied ist die Erfahrung, die dazwischen liegt.

---

**Nächster Post:**  
Crypto-Miner auf meinem Server: Wie ich den Angriff erkannt und gestoppt habe.
