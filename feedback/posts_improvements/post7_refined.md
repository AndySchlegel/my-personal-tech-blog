# Das große Bild: Wie aus einzelnen Projekten eine Hybrid-Infrastruktur mit über 50 Services wurde

**Kategorie:** Homelab & Self-Hosting | **Featured:** Nein | **Lesezeit:** 7 Min | **Datum:** 2026-02-28

**HINWEIS:** Original-Titel war "Multi-Cloud-Architektur" — hier bereits auf "Hybrid-Infrastruktur" korrigiert (CV-Konsistenz)

**Excerpt:** NAS zuhause, zwei Cloud-Server an verschiedenen Standorten, verbunden über Tailscale. Über 50 containerisierte Services, verteilt nach Aufgabe und Ressourcenbedarf. Docker Compose, Shell-Skripte, Monitoring-Stack. Organisch gewachsen aus dem Wunsch, Dinge wirklich zu verstehen.

---

## Vor einem Jahr existierte nichts davon

Wenn ich heute auf mein Homelab schaue, sehe ich etwas, das vor einem Jahr nicht existiert hat: drei Standorte, über 50 containerisierte Services, ein zentrales Monitoring, automatisierte Daten-Pipelines und ein Dashboard, von dem aus ich alles erreiche.

Das war nie so geplant. Es ist organisch gewachsen — Stück für Stück, Service für Service, Problem für Problem. Jedes Mal, wenn ich etwas Neues lernen wollte, habe ich es in die bestehende Infrastruktur integriert. Irgendwann war es keine Spielerei mehr, sondern eine echte Plattform.

---

## Drei Standorte, eine Verbindung

Die Infrastruktur verteilt sich auf drei Standorte:

**Die NAS zuhause** — eine Synology DS925+ mit 32 GB RAM. Sie ist das Herzstück: zentrales Storage, Monitoring-Hub, eigenes GitLab, Wazuh SIEM als Security-Zentrale. Alles, was Daten langfristig speichern oder zentral auswerten muss, läuft hier.

**Ein Cloud-Server in Deutschland** — klein, ressourcenschonend, ARM-basiert. Hier laufen Web-Anwendungen wie n8n für Automatisierung sowie Traefik als Reverse Proxy mit TLS-Terminierung. Services, die von außen erreichbar sein müssen, aber wenig Rechenleistung brauchen.

**Ein zweiter Cloud-Server** — deutlich leistungsstärker, mit 16 vCPUs und 32 GB RAM. Hier laufen datenintensive Workloads: automatisierte Pipelines, die Daten verarbeiten, verifizieren und zwischen Standorten synchronisieren. Dazu Shell-Skripte und Cronjobs in regelmäßigen Intervallen.

Verbunden ist alles über Tailscale. Kein Port Forwarding, keine öffentlich exponierten Services. Jeder Server, jedes Gerät — auch meine beiden MacBooks — hängt im selben verschlüsselten Mesh-Netzwerk. Wenn ich von unterwegs auf Grafana oder Portainer zugreifen will, geht das über die Tailscale-IP. Ohne VPN-Client starten zu müssen, ohne Tunnel manuell aufzubauen. Es funktioniert einfach.

---

## Logik hinter der Verteilung

Die Entscheidung, welcher Service wo läuft, folgt einer einfachen Logik:

**Rechenintensiv und datengetrieben** kommt auf den leistungsstarken Server. Dort stehen genug CPU-Ressourcen und schnelle NVMe-SSDs für I/O-intensive Workloads zur Verfügung. Automatisierte Pipelines verarbeiten Daten, verifizieren die Integrität und synchronisieren sie per rsync auf eine externe Storage Box. Von dort zieht die NAS die Daten über Cloud Sync. Mehrstufig, mit Prüfungen auf jeder Ebene.

**Web-Anwendungen und öffentliche Endpunkte** laufen auf dem kleinen Server. n8n für Webhook-basierte Automatisierung, Traefik für TLS — das braucht wenig Leistung, aber eine stabile öffentliche IP und saubere Zertifikatsverwaltung.

**Alles Zentrale** bleibt auf der NAS. Prometheus sammelt Metriken von allen Standorten. Grafana visualisiert sie. Wazuh aggregiert Security-Events. GitLab hostet meine privaten Repositories. Die NAS ist die einzige Komponente, die nicht in der Cloud läuft — und das ist bewusst so. Hier liegen die Daten, hier laufen die Auswertungen, hier ist die Kontrolle.

---

## Automatisierung: Wo die echte Arbeit steckt

Was mich am meisten überrascht hat: Die eigentliche Arbeit steckt nicht im Aufsetzen der Services, sondern in der Automatisierung drumherum.

Auf dem leistungsstarken Server laufen mehrere Cronjobs in unterschiedlichen Intervallen — von minütlicher Datenverarbeitung bis zu täglichen Cleanup-Routinen. Ein Safety-Net-Skript erkennt hängengebliebene Prozesse und bereinigt sie automatisch.

Das Sync-Skript allein hat über 250 Zeilen. Es synchronisiert Ordner einzeln, vergleicht Dateianzahlen zwischen Quelle und Ziel, löscht erst nach Bestätigung, überwacht den Festplattenspeicher und pausiert Prozesse automatisch, wenn weniger als 20 GB frei sind. Kein einfaches `rsync -r` und hoffen, dass es passt — sondern mehrstufige Verifikation mit Logging.

Shell-Skripte und Cron klingen nicht glamourös. Aber diese Skripte laufen seit Wochen zuverlässig — und genau daran habe ich Fehlerbehandlung, Robustheit und die Realität von Automatisierung wirklich verstanden.

---

## Monitoring: Von Anfang an mitgedacht

Monitoring war kein Nachgedanke — es ist gemeinsam mit der Infrastruktur gewachsen. Von Prometheus und Grafana auf dem ersten Server bis hin zu einem mehrstufigen System mit Uptime Kuma für Verfügbarkeit und Wazuh als SIEM für Security-Events. Jede Erweiterung hatte einen konkreten Auslöser, und jede hat sich bewährt.

Wie das im Detail aussieht, welche Entscheidungen dahinter stecken und warum sich der frühe Start konkret ausgezahlt hat — das ist eine eigene Geschichte.

---

## Dashy: Ein Dashboard für alles

Mein Einstiegspunkt in die gesamte Infrastruktur ist Dashy — ein Self-Hosted Dashboard, das auf der NAS läuft. Darüber erreiche ich alles: Grafana-Dashboards, Portainer für Container-Management, Uptime Kuma, Wazuh, die Synology-Oberfläche, GitLab, meine Webseiten. Sogar die Philips Hue Lampen lassen sich darüber schalten.

Kein Wechseln zwischen Bookmarks, kein Merken von Ports und IPs. Ein Dashboard, alle Services, alle Standorte.

---

## GitLab: Private Repos, selbst gehostet

Neben GitHub für öffentliche Projekte betreibe ich ein eigenes GitLab auf der NAS. Dort liegen alle privaten Repositories — Infrastruktur-Dokumentation, Konfigurationen, Skripte. Alles, was nicht öffentlich sein soll, aber trotzdem versioniert und nachvollziehbar sein muss.

GitLab läuft als Container auf der NAS und ist nur über Tailscale erreichbar. Kein öffentlicher Zugriff, keine Cloud-Abhängigkeit. Meine Daten, mein Server, meine Kontrolle.

---

## Organisch, aber bewusst

Nichts davon war geplant. Es gab keinen Architektur-Entwurf, kein Zieldiagramm. Ich wollte lernen, habe Services aufgesetzt, bin auf Probleme gestoßen, habe sie gelöst — und plötzlich war da eine verteilte Infrastruktur mit über 50 Services.

Aber "organisch gewachsen" heißt nicht "unkontrolliert". Jeder Service hat seinen Platz, jede Entscheidung hat einen Grund. Monitoring läuft zentral, Security ist mehrstufig, Backups sind automatisiert, und jede Konfiguration ist in Git versioniert.

Angefangen mit Docker Compose, Shell-Skripten und Cronjobs — und mit jedem neuen Service, jedem gelösten Problem ist die Infrastruktur und mein Verständnis mitgewachsen. Man wächst an seinen Aufgaben, und dieses Homelab war der beste Beweis dafür.

---

**Nächster Post:**
Monitoring und Security: Warum ich früh angefangen habe und es sich ausgezahlt hat.
