
# Der Moment, an dem Theorie zu Praxis wird

**Kategorie:** Career & Learning | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-02-17

**Excerpt:** Die ersten Monate drehten sich um Grundlagen: Was eigentlich hinter dieser vielzitierten Cloud steckt. Darauf folgten zwei Zertifizierungen, eine als Kursaufgabe entstandene Mockup-Idee, erste Versuche mit Containern – und schließlich der Punkt, an dem aus Theorie eigene Infrastruktur wurde.

---

## Fundamente legen, ohne zu wissen, wohin

März 2025. Erster Tag der Weiterbildung. Die Entscheidung war gefallen – es konnte losgehen.

Linux‑Befehle, Networking‑Basics, Cloud‑Konzepte. Die Struktur war klar und das Tempo hoch. Jeden Tag neue Themen, neue Tools, neue Begriffe.

Ich habe in den ersten Wochen viel mit Tutorials und Labs gearbeitet – verschiedene Anbieter, verschiedene Plattformen. Das hat funktioniert, um die Grundlagen zu verstehen: `ls`, `cd`, `chmod`, erste AWS‑Services, was eine VPC ist oder was ein Load Balancer eigentlich macht.

Aber irgendwann merkt man: Tutorials zeigen dir die perfekte Welt. Schritt für Schritt, alles funktioniert, kein Fehler. Das echte Lernen beginnt erst da, wo Dinge schiefgehen und Probleme auftauchen, die nicht im Tutorial stehen.

---

## Lernen, um weiterzukommen

Juni 2025: AWS Cloud Practitioner bestanden. Das war der erste echte Meilenstein. IAM, VPC, S3, EC2 – nicht nur als Begriffe, sondern als Services, deren Zusammenspiel langsam greifbar wurde.

Juli 2025: Linux Essentials bestanden. Kommandozeile, Dateisystem, Paketmanagement, grundlegende Administration. Die Sicherheit, sich auf einem Linux‑System bewegen zu können, ohne bei jedem Befehl nachschlagen zu müssen.

Beide Zertifizierungen waren eine Mischung aus Kursarbeit und Selbststudium. Der Kurs hat die Grundlage gelegt – die Tiefe kam erst durch eigenes Ausprobieren.

Zertifizierungen zeigen Wissen. Erfahrung beginnt erst, wenn man etwas Eigenes baut.

---

## Von Wissen zu Können

Ausgangspunkt war ein Dashboard‑Mockup, das nach konkreten Stakeholder‑Anforderungen umgesetzt wurde – ein kompaktes Übungsprojekt vom Entwurf bis zur Präsentation.

Ich habe das Projekt weitergeführt. Das Dashboard lokal zum Laufen zu bringen war das eine – aber ich wollte wissen, wie ich es in die Cloud bekomme.

Also habe ich es auf AWS mit ECS deployed: ein Dockerfile gebaut, das Image nach ECR gepusht, den ECS‑Task konfiguriert und den Service gestartet. Mein erster echter Kontakt mit Containern und Cloud‑Deployments – kein Lab‑Szenario, sondern mein eigenes Projekt.

Es hat funktioniert. Und genau in diesem Moment hat sich etwas verändert. Ab diesem Punkt habe ich bewusst nach Möglichkeiten gesucht, Theorie in eigene Infrastruktur zu überführen.

---

## Der erste eigene Stack

Das Dashboard lief auf ECS – aber in der Sandbox‑Umgebung der Weiterbildung. Abhängig von Kostenlimits, nicht dauerhaft verfügbar. Ich wollte das anders.

Also habe ich für kleines Geld einen Hetzner‑Cloud‑Server aufgesetzt. Ubuntu installiert, Docker eingerichtet, Services mit Docker Compose betrieben, eine Domain registriert und DNS konfiguriert.

Das war ein völlig anderes Lernen als das ECS‑Deployment. Auf einem eigenen Server bist du für alles verantwortlich: Betriebssystem, Updates, Firewall, Netzwerk, Backups. Wenn etwas nicht läuft, gibt es keinen Managed Service, der das Problem für dich löst.

---

## Weniger Theorie, mehr eigenes Setup

Zwei Zertifizierungen. Ein Projekt, das sowohl auf AWS als auch auf eigener Infrastruktur lief. Erste Erfahrungen mit Containern, Deployments, Domains und selbst betriebener Infrastruktur.

Und die Erkenntnis: Lernen funktioniert für mich am besten, wenn ich etwas Echtes baue und betreibe.

Der nächste Schritt kam fast zwangsläufig.

---

**Nächster Post:**  
Blackbox kaputt: Vom Provider‑Router zum eigenen Netzwerk
