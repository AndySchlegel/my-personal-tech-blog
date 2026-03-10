# Blog Posts Review -- Gesamtkontext und alle 11 Posts

## Prompt / Kontext fuer die Optimierung

Du reviewst die 11 Blog-Posts eines Tech-Blogs von Andy Schlegel -- Career Changer (Sales -> Cloud & DevOps). Der Blog ist gleichzeitig Portfolio-Stueck und dauerhaftes Projekt.

### Wer ist Andy?
- Fast 20 Jahre B2B Sales (Endkunde bis Key Account), 6 Jahre Bundeswehr
- Career Change 2025: Vollzeit-Weiterbildung "Java DevOps Engineer" (CloudHelden)
- 4 Zertifizierungen: AWS Cloud Practitioner, LPI Linux Essentials, AWS Solutions Architect, GitHub Foundations
- IHK Berufsspezialist Systemintegration gestartet (Feb 2026)
- Produktives Homelab: 50+ containerisierte Services, 4 Umgebungen (NAS, Hetzner, Lokal, AWS)
- 2 AWS-Projekte: EcoKart Webshop (Serverless, 15 TF-Module) + dieser Blog (EKS, 9 TF-Module)

### Zielgruppe
Engineering Manager und DevOps-Teamleads, die einen Junior/Mid-Kandidaten evaluieren.

### Ton und Stil
- Deutsch, technische Begriffe englisch
- Authentisch, ehrlich ueber den Lernprozess
- Technisch praezise, keine kuenstliche Sprache
- Fehler zeigen erhoehen Glaubwuerdigkeit
- "Engineering Insights" statt Tagebuch-Eintraege
- Keine externen Quellen/Credits referenzieren
- Keine Karriereziele oder Zertifizierungen annehmen die nicht bestaetigt sind

### CV-Konsistenz (wichtig!)
- "fast zwei Jahrzehnte" = kanonisch fuer Sales-Erfahrung
- "Hybrid-Infrastruktur" statt "Multi-Cloud" (kein AWS+Azure+GCP implizieren)
- 4 Umgebungen (NAS, Hetzner, Lokal, AWS) -- nicht "Standorte" im Multi-Cloud-Kontext
- EcoKart = 15 TF-Module, Blog = 9 TF-Module, gesamt 25+
- 31 Tests (Blog) + 63 Tests (EcoKart) = 94 automatisierte Tests
- Kein "Multi-Cloud" verwenden

### Blog-Struktur
- 7 Kategorien: AWS & Cloud, DevOps & CI/CD, Homelab & Self-Hosting, Networking & Security, Tools & Productivity, Certifications, Career & Learning
- Posts erzaehlen chronologisch den Weg vom Career Change bis zum Abschlussprojekt
- Post 12 kommt spaeter als Live-Proof-of-Concept via Admin Dashboard

### Was bei der Optimierung beachten
1. **Inhaltliche Praezision**: Stimmen Zahlen, Tech-Details, Timelines mit CV ueberein?
2. **Redundanzen**: Wiederholen sich Formulierungen/Geschichten ueber Posts hinweg?
3. **Ton**: Klingt es nach Engineering Insight oder nach Tagebuch?
4. **Struktur**: Problem -> Ansatz -> Loesung -> Lessons Learned?
5. **"Multi-Cloud"**: Muss ueberall durch "Hybrid" oder aehnliches ersetzt werden
6. **Wirkung auf Recruiter**: Zeigt jeder Post technische Kompetenz?

---

## Post 1: Erfahrung trifft Neuanfang -- mein Weg in Cloud & DevOps
**Kategorie:** Career & Learning | **Featured:** Ja | **Lesezeit:** 5 Min | **Datum:** 2026-02-14

**Excerpt:** Fast 20 Jahre Vertriebserfahrung, verschiedene Branchen, ein Kern: in Loesungen denken. Dann die Entscheidung, die technische Seite nicht nur zu verstehen, sondern selbst zu bauen. Zwoelf Monate spaeter: vier Zertifizierungen, ein produktives Homelab mit ueber 50 Services, ein Webshop auf AWS -- und dieser Blog als Beweis dafuer, dass Erfahrung und Neuanfang sich nicht ausschliessen, sondern verstaerken.

### Inhalt:

#### Stabilitaet durch Veraenderung

In verschiedenen Branchen, ueber verschiedene Stationen hinweg, war eines immer gleich: Im Zentrum stand der Kunde. Erst im direkten Endkundengeschaeft, spaeter zunehmend im B2B-Umfeld. Beduerfnisse verstehen, Rahmenbedingungen kennen -- Vorgaben, Budgets, Einschraenkungen -- und innerhalb dieses Rahmens alltagstaugliche Loesungen entwickeln. Das hat mich fast zwei Jahrzehnte lang gepraegt und angetrieben.

In den letzten Jahren kam ein zusaetzlicher Fokus dazu. Die Themen wurden technischer. Gemeinsam mit Kunden, Teams aus Business Development, IT und Projektverantwortlichen haben wir Schnittstellenanbindungen konzipiert, Prozesse zwischen Dienstleister und Kunde effizienter gestaltet, Anforderungen und technische Moeglichkeiten zusammengefuehrt.

Da fielen Begriffe wie API und Systemintegration -- und was auf der technischen Seite aus unseren Anforderungen entstand, hat mich zunehmend fasziniert.

Die Neugier war geweckt!

#### Ein Impuls, der geblieben ist

Dann begann eine Phase der Veraenderung. Ich habe mir eine Auszeit genommen, einen Schritt zurueckgetreten -- und mir Fragen gestellt, die im Alltag keinen Platz gehabt hatten. Will ich weiter ausschliesslich im Vertrieb bleiben? Oder steckt in der Faszination fuer Technik mehr als nur Interesse -- naemlich ein echter naechster Schritt?

Je ehrlicher ich hingeschaut habe, desto klarer wurde das Bild. Die technische Affinitaet war schon immer da. Die Gespraeche mit IT-Abteilungen hatten Tueren geoeffnet. Und die Erkenntnis, dass meine bisherigen Faehigkeiten -- Anforderungen verstehen, in Loesungen denken, Perspektiven verbinden -- auch in der Tech-Welt gefragt sind, gab den Ausschlag.

Cloud und DevOps, weil es genau an dieser Schnittstelle liegt: Dort, wo Systeme nicht nur gedacht, sondern gebaut und betrieben werden. Und ergebnisoffen -- ob der Weg beispielsweise als Cloud Engineer in eine technische Rolle fuehrt, als Solutions Architect beide Welten verbindet oder Richtung Technical Consulting geht. Kein festgelegtes Ziel, sondern ein Fundament, das verschiedene Richtungen ermoeglicht.

#### Vom weissen Blatt zur laufenden Infrastruktur

Zwoelf Monate voller Cloud- und DevOps-Praxis, in Vollzeit und ohne technische Vorerfahrung.

Was daraus entstanden ist, hat mich selbst ueberrascht. Ein Homelab mit ueber 50 Services auf drei Standorten, das taeglich stabil laeuft. Ein vollstaendiger Webshop auf AWS als Showcase fuer Serverless-Architektur. Zertifizierungen, die das Wissen untermauern. Und dieser Blog -- auf AWS EKS gebaut, um Kubernetes in der Praxis zu zeigen, dauerhaft gehostet auf eigener Infrastruktur mit K3s.

Jedes dieser Projekte hat seine eigene Geschichte. Dieser Blog erzaehlt sie.

#### Kein Abschluss, ein Zwischenschritt

Direkt danach begann die IHK-Qualifikation zum Berufsspezialisten fuer Systemintegration und Vernetzung -- die gezielte Vertiefung, um das Gelernte auf ein formales Fundament mit Gewicht in der Branche zu stellen. Jeder Schritt baut auf dem vorherigen auf, und dieser Weg ist noch lange nicht zu Ende.

#### Ein Beitrag pro Etappe

Entscheidungen und deren Begruendungen. Loesungswege, die auf Anhieb funktioniert haben -- und andere, die mehrere Iterationen gebraucht haben. Von der ersten Kommandozeile bis zur Cloud-Native Anwendung auf Kubernetes.

**Naechster Post:** Der Moment, an dem Theorie zu Praxis wird

---

## Post 2: Der Moment, an dem Theorie zu Praxis wird
**Kategorie:** Career & Learning | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-02-17

**Excerpt:** Die ersten Monate drehten sich um Grundlagen: Was eigentlich hinter dieser vielzitierten Cloud steckt. Darauf folgten zwei Zertifizierungen, eine als Kursaufgabe entstandene Mockup-Idee, erste Versuche mit Containern -- und schliesslich der Punkt, an dem aus Theorie eigene Infrastruktur wurde.

### Inhalt:

#### Fundamente legen, ohne zu wissen, wohin

Maerz 2025. Erster Tag der Weiterbildung. Die Entscheidung war gefallen -- es konnte losgehen.

Linux-Befehle, Networking-Basics, Cloud-Konzepte. Die Struktur war klar -- und das tat gut. Jeden Tag neue Themen, schnelles Tempo, viel Input.

Ich habe in den ersten Wochen viel mit Tutorials und Labs gearbeitet -- verschiedene Anbieter, verschiedene Plattformen. Das hat funktioniert, um die Grundlagen zu verstehen. `ls`, `cd`, `chmod`, erste AWS-Services, was ist eine VPC, was macht ein Load Balancer.

Aber irgendwann merkt man: Tutorials zeigen dir die perfekte Welt. Schritt fuer Schritt, alles funktioniert, kein Fehler. Das echte Lernen beginnt erst da, wo man auf Probleme stoesst, die nicht im Tutorial stehen.

#### Lernen, um weiterzukommen

Juni 2025: AWS Cloud Practitioner bestanden. Das war der erste richtige Meilenstein. IAM, VPC, S3, EC2 -- nicht nur als Konzepte, sondern verstanden, was die Services tun und wie sie zusammenspielen.

Juli 2025: Linux Essentials bestanden. Kommandozeile, Dateisystem, Paketmanagement, grundlegende Administration. Die Sicherheit, sich auf einem Linux-System bewegen zu koennen, ohne bei jedem Befehl nachschlagen zu muessen.

Beide Zertifizierungen waren eine Mischung aus Kursarbeit und Selbststudium. Der Kurs hat die Grundlage gelegt, die Tiefe kam durch eigenes Vertiefen und Ausprobieren.

Zertifizierungen zeigen Wissen -- aber Erfahrung beginnt erst, wenn man etwas Eigenes aufbaut.

#### Von Wissen zu Koennen

Ausgangspunkt war ein Dashboard-Mockup, das nach konkreten Stakeholder-Anforderungen umgesetzt wurde -- ein kompaktes Uebungsprojekt vom Entwurf bis zur Praesentation.

Ich habe das Projekt weitergefuehrt. Das Dashboard lokal zum Laufen zu bringen war das eine -- aber ich wollte wissen, wie ich es in die Cloud bringe.

Also habe ich es auf AWS mit ECS deployed: ein Dockerfile gebaut, das Image nach ECR gepusht, den ECS-Task konfiguriert und den Service gestartet. Mein erster echter Kontakt mit Containern und Cloud-Deployments -- kein Lab-Szenario, sondern mein eigenes Projekt.

Es hat funktioniert. Und genau da hat sich etwas veraendert. Ab dem Punkt habe ich angefangen, bewusst nach Moeglichkeiten zu suchen, Theorie in Praxis umzusetzen.

#### Der erste eigene Stack

Das Dashboard lief auf ECS -- aber in der Sandbox-Umgebung der Weiterbildung. Abhaengig von Kostenlimits, nicht dauerhaft verfuegbar. Ich wollte das anders.

Also habe ich fuer kleines Geld einen Hetzner Cloud Server aufgesetzt. Ubuntu drauf, Docker installiert, Services per Docker Compose konfiguriert, eine Domain gekauft und DNS eingerichtet.

Das war ein komplett anderes Lernen als das ECS-Deployment. Auf einem eigenen Server bist du fuer alles verantwortlich: Betriebssystem, Updates, Firewall, Netzwerk, Backups. Wenn etwas nicht laeuft, faengt dich kein Managed Service auf.

#### Weniger Theorie, mehr eigenes Setup

Zwei Zertifizierungen. Ein Projekt, das sowohl auf AWS als auch auf eigenem Server lief. Erste Erfahrung mit Containern, Deployments, Domains und eigenverantworteter Infrastruktur. Und die Erkenntnis: Lernen funktioniert fuer mich am besten, wenn ich etwas Echtes baue und betreibe.

**Naechster Post:** Blackbox kaputt

---

## Post 3: Blackbox kaputt: Vom Provider-Router zum eigenen Netzwerk
**Kategorie:** Homelab & Self-Hosting | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-02-19

**Excerpt:** NAS bestellt, Hetzner-Server lief schon -- aber der Telekom-Router liess sich kaum konfigurieren. Das war der Punkt, an dem ich mein eigenes Netzwerk mit Enterprise-Hardware aufgebaut habe. Wie aus den Limitierungen eines Consumer-Routers ein vollstaendiges Homelab gewachsen ist.

### Inhalt:

#### Am Limit des Provider-Routers

Ich hatte zu dem Zeitpunkt bereits meinen Hetzner-Server und eine frisch eingerichtete Synology NAS. Zwei Systeme, die miteinander kommunizieren sollten -- und ein Netzwerk, das ich dafuer flexibel konfigurieren musste.

Der Telekom-Router war ein geschlossenes System. Stark eingeschraenkt konfigurierbar. Sobald man mehr als Standard-Internetnutzung braucht, stoesst man schnell an die Grenzen.

Also habe ich entschieden: Eigenes Netzwerk, eigene Regeln -- mit echter Enterprise-Technik.

#### UniFi: Mein Netzwerk, meine Regeln

Die Entscheidung fiel auf Ubiquiti UniFi -- Cloud Gateway Fiber, Access Point, Modem. Enterprise-Hardware, die in professionellen Umgebungen eingesetzt wird.

Der Unterschied war sofort spuerbar. Ploetzlich konnte ich alles konfigurieren -- Firewall-Regeln, VLANs, Traffic-Management, den gesamten Netzwerkverkehr ueberwachen und steuern.

Das war gleichzeitig ein massives Lernfeld. Subnetting, Firewall-Rules, DNS, DHCP -- alles Themen, die man in der Theorie schnell versteht. Aber ein eigenes Netzwerk designen, in dem mehrere Geraete und Server sauber miteinander kommunizieren, ist eine andere Dimension.

#### Mehr als nur Storage

Die NAS habe ich aus mehreren Gruenden angeschafft: Homelab-Plattform fuer Container, eigene Cloud-Loesung fuer Daten/Backups, und ein System an dem ich lerne wie man Infrastruktur betreibt.

#### Wenn Bausteine zusammenspielen

Mit NAS, Hetzner-Server und UniFi-Netzwerk hatte ich jetzt mehrere Systeme, die laufen und ueberwacht werden wollen. Prometheus als Datenlieferant, Grafana als Dashboard, Dashy als zentraler Einstiegspunkt.

#### Automatisieren statt wiederholen

n8n auf der NAS: Automatisierte Workflows, die Systeme miteinander verbinden -- Benachrichtigungen, Datenabgleich, wiederkehrende Aufgaben.

#### Cloud nutzen, Homelab verantworten

Im Rueckblick war der Homelab-Aufbau die wichtigste Entscheidung dieser Phase. In der Cloud lernst du, Services zu nutzen. Im Homelab lernst du, Infrastruktur zu betreiben.

**Naechster Post:** Sichere Infrastruktur von Tag 1

---

## Post 4: Sichere Infrastruktur von Tag 1: VPN, Reverse Proxy und Networking in der Praxis
**Kategorie:** Networking & Security | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-02-21

**Excerpt:** NAS und Hetzner-Server standen -- aber wie verbinde ich sie sicher miteinander? Erst WireGuard, dann Tailscale. Erst Nginx, dann Traefik. Viel ausprobiert, vieles verworfen, dabei mehr Networking gelernt als jedes Tutorial vermittelt.

### Inhalt:

- WireGuard auf Synology gescheitert (fragile Drittanbieter-Pakete)
- Tailscale als Loesung: nativ im Synology Paketzentrum, Mesh-VPN
- Nginx Proxy Manager -> Traefik Migration (Labels statt GUI)
- DNS, SSL, Reverse Proxy durch Debugging gelernt
- Architektur: Tailscale intern, Reverse Proxy extern, klare Trennung
- Lektion: "Nicht ewig kaempfen, sondern das richtige Tool finden"

**Naechster Post:** Sandbox kaputt, alles weg

---

## Post 5: Sandbox kaputt, alles weg -- wie ich Terraform lieben gelernt habe
**Kategorie:** DevOps & CI/CD | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-02-24

**Excerpt:** Ein Wochenende Arbeit am EcoKart-Webshop, Montagmorgen alles geloescht. Ein automatischer Cleanup-Workflow in der Sandbox-Umgebung hat jeden Fortschritt vernichtet. Das war der Moment, in dem Reproduzierbarkeit Pflicht wurde -- und Terraform mein wichtigstes Werkzeug.

### Inhalt:

- Sandbox-Wipe: Kostenlimit ueberschritten, naechtlicher Auto-Delete
- Mindshift: "Wie geht es besser?" statt Frust
- Terraform selbst beigebracht (stand nicht auf dem Lehrplan)
- EcoKart komplett in Terraform nachgebaut
- SCP-Limitierungen: "Tod durch tausend Freischaltungen"
- Eigener AWS Account: keine Limits, eigene Verantwortung
- CI/CD Pipeline mit GitHub Actions aufgebaut
- EcoKart Stand: 15 TF-Module, 12 AWS-Services, 63 Tests, OIDC, ~10 USD/Monat

**Naechster Post:** EcoKart: Mein erster vollstaendiger Webshop auf AWS

---

## Post 6: EcoKart: Mein erster vollstaendiger Webshop auf AWS
**Kategorie:** AWS & Cloud | **Featured:** Ja | **Lesezeit:** 7 Min | **Datum:** 2026-02-26

**Excerpt:** Ein Kurs-Rechercheprojekt ueber Infrastruktur-Kosten brachte mich auf die Idee, einen echten Webshop auf AWS zu bauen. 12 Services, 15 Terraform-Module, Stripe-Zahlungen, Cognito-Authentifizierung -- und eine Email-Provider-Odyssee, die mich am Neujahrstag bei Resend landen liess.

### Inhalt:

- Gruppenarbeit als Anstoß -> eigenes Projekt
- Serverless Architektur: Lambda, DynamoDB, API Gateway, Amplify, S3, CloudFront, Cognito, Route53, ACM, CloudWatch
- 12 AWS-Services, 15 TF-Module, ~10-15 USD/Monat
- OIDC statt AWS-Keys: temporaere Credentials, kein Key im Repo
- Cognito: "Authentifizierung, die sich gewehrt hat"
- Stripe: stabile Endpoints erzwingen (Custom Domains)
- Email-Odyssee: SES abgelehnt -> SendGrid abgelehnt -> Resend am Neujahrstag
- 63 Tests mit Jest, Integrationstests ueber LocalStack
- "EcoKart hat mir mehr ueber AWS beigebracht als jeder Kurs"

**Naechster Post:** Das grosse Bild

---

## Post 7: Das grosse Bild: Wie aus einzelnen Projekten eine Multi-Cloud-Architektur mit ueber 50 Services wurde
**Kategorie:** Homelab & Self-Hosting | **Featured:** Nein | **Lesezeit:** 7 Min | **Datum:** 2026-02-28

**ACHTUNG: Titel und Inhalt verwenden "Multi-Cloud" -- muss auf "Hybrid" geaendert werden!**

**Excerpt:** NAS zuhause, zwei Cloud-Server an verschiedenen Standorten, verbunden ueber Tailscale. Ueber 50 containerisierte Services, verteilt nach Aufgabe und Ressourcenbedarf. Docker Compose, Shell-Skripte, Monitoring-Stack. Organisch gewachsen aus dem Wunsch, Dinge wirklich zu verstehen.

### Inhalt:

- 3 Standorte (NAS, kleiner Hetzner, grosser Hetzner), verbunden ueber Tailscale
- NAS: Monitoring-Hub, GitLab, Wazuh SIEM, zentrales Storage
- Kleiner Server: Web-Apps, n8n, Traefik
- Grosser Server: datenintensive Workloads, Pipelines, Cronjobs
- Sync-Skript: 250+ Zeilen, mehrstufige Verifikation
- Automatisierung: Cronjobs, Safety-Net-Skripte, rsync
- Dashy als zentrales Dashboard
- GitLab self-hosted auf NAS
- "Organisch gewachsen, aber bewusst"

**Naechster Post:** Monitoring und Security

---

## Post 8: Monitoring und Security: Warum ich frueh angefangen habe und es sich ausgezahlt hat
**Kategorie:** Networking & Security | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-03-03

**Excerpt:** Prometheus und Grafana liefen schon auf meinem ersten Server. Was als einfaches Ressourcen-Monitoring begann, ist Stueck fuer Stueck zu einem mehrstufigen System gewachsen -- Uptime Kuma fuer Verfuegbarkeit, Wazuh als SIEM fuer Security-Events, Telegram als zentraler Alarmkanal.

### Inhalt:

- Prometheus/Grafana: erste Metriken auf dem ersten Server
- Zentralisierung auf NAS: 16 Targets, 15-Sekunden Scraping
- 3 Grafana-Dashboards (pro Server + Multi-Server-Overview)
- Uptime Kuma: 12 Services, 60-Sekunden-Takt
- Ernstfall: Naechtlicher Alert unterwegs, Remote-Debugging ueber Tailscale
- Server-Haertung nach Vorfall: Docker auf 127.0.0.1, UFW, fail2ban, Tailscale-only
- Watchtower + Unattended-Upgrades fuer automatische Updates
- Wazuh SIEM: Manager + Agents, Docker-Listener, Severity-basiertes Alerting
- Dreistufiges Alerting: Grafana (Performance) + Uptime Kuma (Verfuegbarkeit) + Wazuh (Security)
- Alles auf Telegram

**Naechster Post:** Crypto-Miner auf meinem Server

---

## Post 9: Crypto-Miner auf meinem Server: Wie ich den Angriff erkannt und gestoppt habe
**Kategorie:** Networking & Security | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-03-05

**Excerpt:** Die NAS neben mir wird ploetzlich ohrenbetaeubend laut, Telegram meldet CPU-Auslastung ueber 200 Prozent. In unter drei Minuten war der Verursacher identifiziert und isoliert.

### Inhalt:

- NAS auf Maximum, Grafana-Alert: CPU ueber 200%
- Systematisches Vorgehen: Container identifiziert (alter Blog-Container mit offener MongoDB)
- Schwachstelle: Altlast aus der Lernphase, Monate deaktiviert, bei Reaktivierung sofort kompromittiert
- "Das Internet scannt systematisch nach offenen Datenbanken. Stunden reichen."
- Bereinigung: DB abgesichert, alle Credentials rotiert, alle Container geprueft
- Monitoring als Unterschied: haette auch remote funktioniert
- Lektionen: Alte Configs leben weiter, Monitoring ist nicht optional, strukturiertes Vorgehen zahlt sich aus

**Naechster Post:** AWS Solutions Architect

---

## Post 10: AWS Solutions Architect: Warum ich die Pruefung mit Praxis statt nur Theorie vorbereitet habe
**Kategorie:** Certifications | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-03-08

**Excerpt:** AWS Solutions Architect -- die Pruefung, die nicht fragt was ein Service macht, sondern welche Loesung zu welchem Problem passt. Vorbereitet mit eigenem AWS-Account, echten Projekten und dem Anspruch, jedes Thema wirklich zu durchdringen.

### Inhalt:

- "Solutions, nicht Services" -- Parallele zu Sales-Denkweise
- Kombination: theoretische Breite + praktische Tiefe (eigener AWS-Account)
- Eigene Lernmaterialien: Flashcards, Quizzes, Service-Vergleichskarten
- Practice Tests ueber mehrere Plattformen, Fehleranalyse wichtiger als richtige Antworten
- Enterprise-Szenarien: ueber das Homelab hinaus (Multi-Account, Migrationen, Hybrid)
- Englisch: feinste Nuancen ("cost-effective" vs. "cheapest")
- "Mehr als ein Zertifikat" -- Architektur-Entscheidungen auf hoeherem Niveau
- Bestanden: Februar 2026

**Naechster Post:** Diesen Blog auf AWS EKS deployen

---

## Post 11: Diesen Blog auf AWS EKS deployen: Mein Abschlussprojekt
**Kategorie:** DevOps & CI/CD | **Featured:** Ja | **Lesezeit:** 7 Min | **Datum:** 2026-03-12

**Excerpt:** Das Abschlussprojekt meiner Weiterbildung: Diesen Tech-Blog als Cloud-Native Anwendung auf AWS EKS bauen. Neun Terraform-Module, sechs CI/CD-Pipelines, OIDC statt AWS-Keys und eine Wave-Strategie, die Kosten kontrollierbar macht.

### Inhalt:

- Bewusste Entscheidung fuer EKS statt Serverless (Enterprise-Naehe, K8s-Praxis)
- 9 Terraform-Module: VPC, Security Groups, EKS, RDS, CloudFront, S3, Cognito, ECR, OIDC
- Spot Instances, Pod Anti-Affinity, Health Probes, Resource Limits
- OIDC statt AWS-Keys: nur 2 Secrets statt 4
- 6 CI/CD Pipelines: Deploy, Terraform, Security-Scan, Infra-Provision, Infra-Destroy, Lint
- Wave-Strategie: Wave 1 (kostenlos) -> Wave 2 (DB, ~13 USD) -> Wave 3 (Full Stack, ~100 USD)
- EKS + K3s: "Zwei Welten" -- Enterprise vs. Self-Hosted
- "Reproduzierbar, nicht einmalig" -- alles in Code
- "Dieses Projekt bringt alles zusammen"

---

## Bekannte Probleme / Optimierungsbedarf

1. **"Multi-Cloud" in Post 7** -- Titel und Inhalt muessen auf "Hybrid" geaendert werden
2. **"drei Standorten" in Post 1** -- sollte "vier Umgebungen" sein (NAS, Hetzner, Lokal, AWS)
3. **Post 7 erwaehnt nur 3 Standorte** -- AWS fehlt als vierte Umgebung
4. **Redundanzen pruefen**: Sales-Hintergrund wird in Post 1, 10 erwaehnt -- konsistent?
5. **Ton**: Manche Posts (1, 2) lesen sich eher als Tagebuch, andere (5, 9, 11) als Engineering Insights
6. **Post-uebergreifende Verweise**: "Naechster Post" Links pruefen
7. **Zahlen-Konsistenz**: 15 TF-Module (EcoKart), 9 (Blog), 25+ gesamt -- ueberall korrekt?
