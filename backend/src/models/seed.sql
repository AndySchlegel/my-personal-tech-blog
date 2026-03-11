BEGIN;

-- Clean slate (safe to re-run)
DELETE FROM post_tags;
DELETE FROM comments;
DELETE FROM posts;
DELETE FROM tags;
DELETE FROM categories;
DELETE FROM users;

-- Reset auto-increment counters
ALTER SEQUENCE users_id_seq RESTART WITH 1;
ALTER SEQUENCE categories_id_seq RESTART WITH 1;
ALTER SEQUENCE posts_id_seq RESTART WITH 1;
ALTER SEQUENCE tags_id_seq RESTART WITH 1;
ALTER SEQUENCE comments_id_seq RESTART WITH 1;

-- Admin user
INSERT INTO users (cognito_id, email, display_name, role)
VALUES ('seed-admin-placeholder', 'andy@schlegel.dev', 'Andy Schlegel', 'admin');

-- Categories
INSERT INTO categories (name, slug, description) VALUES
  ('AWS & Cloud',            'aws-cloud',            'AWS Services, Cloud Architecture and Best Practices'),
  ('DevOps & CI/CD',         'devops-ci-cd',         'CI/CD Pipelines, Docker, Kubernetes and Infrastructure as Code'),
  ('Homelab & Self-Hosting',  'homelab-self-hosting', 'NAS, Server, Self-Hosted Services and Homelab Projects'),
  ('Networking & Security',   'networking-security',  'VPN, Firewall, Monitoring and Security Best Practices'),
  ('Tools & Productivity',    'tools-productivity',   'Development Tools, Terminal Setup and Workflow Automation'),
  ('Certifications',          'certifications',       'AWS Certifications, Study Plans and Exam Tips'),
  ('Career & Learning',       'career-learning',      'Career Change, Learning Journey and Professional Development');

-- Tags
INSERT INTO tags (name, slug, source) VALUES
  ('Career', 'career', 'manual'),
  ('Cloud', 'cloud', 'manual'),
  ('DevOps', 'devops', 'manual'),
  ('Learning', 'learning', 'manual'),
  ('AWS', 'aws', 'manual'),
  ('Certification', 'certification', 'manual'),
  ('Linux', 'linux', 'manual'),
  ('Docker', 'docker', 'manual'),
  ('Homelab', 'homelab', 'manual'),
  ('NAS', 'nas', 'manual'),
  ('Synology', 'synology', 'manual'),
  ('Networking', 'networking', 'manual'),
  ('Monitoring', 'monitoring', 'manual'),
  ('VPN', 'vpn', 'manual'),
  ('Tailscale', 'tailscale', 'manual'),
  ('Traefik', 'traefik', 'manual'),
  ('DNS', 'dns', 'manual'),
  ('Terraform', 'terraform', 'manual'),
  ('CI/CD', 'ci-cd', 'manual'),
  ('GitHub', 'github', 'manual'),
  ('Serverless', 'serverless', 'manual'),
  ('Cognito', 'cognito', 'manual'),
  ('Stripe', 'stripe', 'manual'),
  ('Self-Hosting', 'self-hosting', 'manual'),
  ('Automation', 'automation', 'manual'),
  ('Hetzner', 'hetzner', 'manual'),
  ('Security', 'security', 'manual'),
  ('Prometheus', 'prometheus', 'manual'),
  ('Grafana', 'grafana', 'manual'),
  ('Wazuh', 'wazuh', 'manual'),
  ('Kubernetes', 'kubernetes', 'manual'),
  ('EKS', 'eks', 'manual');

-- Post 1: Erfahrung trifft Neuanfang -- mein Weg in Cloud & DevOps
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Erfahrung trifft Neuanfang -- mein Weg in Cloud & DevOps',
  'erfahrung-trifft-neuanfang',
  '### Stabilität durch Veränderung

In verschiedenen Branchen, über verschiedene Stationen hinweg, war eines immer gleich: Im Zentrum stand der Kunde. Erst im direkten Endkundengeschäft, später zunehmend im B2B-Umfeld. Bedürfnisse verstehen, Rahmenbedingungen kennen -- Vorgaben, Budgets, Einschränkungen -- und innerhalb dieses Rahmens alltagstaugliche Lösungen entwickeln. Das hat mich fast zwei Jahrzehnte geprägt und angetrieben.

In den letzten Jahren wurden die Themen zunehmend technischer. Gemeinsam mit Kunden, Teams aus Business Development, IT und Projektverantwortlichen haben wir Schnittstellenanbindungen konzipiert, Prozesse zwischen Dienstleister und Kunde effizienter gestaltet und Anforderungen mit technischen Möglichkeiten zusammengeführt.

Da fielen Begriffe wie API und Systemintegration -- und was auf der technischen Seite aus unseren Anforderungen entstand, hat mich immer stärker fasziniert.

Die Neugier war geweckt.

---

### Ein Impuls, der geblieben ist

Dann begann eine Phase der Veränderung. Ich habe mir bewusst eine Auszeit genommen, einen Schritt zurückgetreten -- und mir Fragen gestellt, die im Alltag selten Platz haben. Will ich weiter ausschließlich im Vertrieb bleiben? Oder steckt in der Faszination für Technik mehr als nur Interesse -- nämlich ein echter nächster Schritt?

Je ehrlicher ich hingeschaut habe, desto klarer wurde das Bild. Die technische Affinität war schon immer da. Die Gespräche mit IT-Abteilungen hatten Türen geöffnet. Und die Erkenntnis, dass meine bisherigen Fähigkeiten -- Anforderungen verstehen, in Lösungen denken, Perspektiven verbinden -- auch in der Tech-Welt gefragt sind, gab den Ausschlag.

Cloud und DevOps, weil es genau an dieser Schnittstelle liegt: dort, wo Systeme nicht nur geplant, sondern gebaut und betrieben werden. Kein festgelegtes Ziel, sondern ein Fundament, das verschiedene Richtungen ermöglicht -- ob Cloud Engineering, Solutions Architecture oder Technical Consulting.

---

### Vom weißen Blatt zur laufenden Infrastruktur

Zwölf Monate voller Cloud- und DevOps-Praxis -- in Vollzeit und ohne technische Vorerfahrung.

Was daraus entstanden ist, hat mich selbst überrascht. Ein Homelab mit über 50 Services, verteilt über vier Umgebungen -- NAS, Hetzner, lokale Infrastruktur und AWS -- das täglich stabil läuft. Ein vollständiger Webshop auf AWS als Showcase für serverlose Architektur. Zertifizierungen, die das Wissen untermauern. Und dieser Blog -- auf AWS EKS gebaut, um Kubernetes in der Praxis zu zeigen, dauerhaft gehostet auf einer kosteneffizienten Lightsail Instance.

Jedes dieser Projekte hat seine eigene Geschichte. Dieser Blog erzählt sie.

---

### Kein Abschluss, ein Zwischenschritt

Direkt danach begann die IHK-Qualifikation zum Berufsspezialisten für Systemintegration und Vernetzung -- die gezielte Vertiefung, um das Gelernte auf ein formales Fundament mit Gewicht in der Branche zu stellen.

Zertifikate und Projekte sind das Fundament. Entscheidend ist die Fähigkeit, Systeme zu verstehen, sie reproduzierbar aufzubauen und zuverlässig zu betreiben.

Genau darum geht es in diesem Blog.

---

### Ein Beitrag pro Etappe

Entscheidungen und deren Begründungen. Lösungswege, die auf Anhieb funktioniert haben -- und andere, die mehrere Iterationen gebraucht haben. Von der ersten Kommandozeile bis zur Cloud-Native Anwendung auf Kubernetes.',
  'Fast 20 Jahre Vertriebserfahrung, verschiedene Branchen, ein Kern: in Lösungen denken. Dann die Entscheidung, die technische Seite nicht nur zu verstehen, sondern selbst zu bauen. Zwölf Monate später: vier Zertifizierungen, ein produktives Homelab mit über 50 Services, ein Webshop auf AWS -- und dieser Blog als Beweis dafür, dass Erfahrung und Neuanfang sich nicht ausschließen, sondern verstärken.',
  'published', true, 5, 1, 7,
  '2026-02-14T10:00:00Z'
);

-- Post 2: Der Moment, an dem Theorie zu Praxis wird
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Der Moment, an dem Theorie zu Praxis wird',
  'theorie-zu-praxis',
  '### Fundamente legen, ohne zu wissen, wohin

März 2025. Erster Tag der Weiterbildung. Die Entscheidung war gefallen -- es konnte losgehen.

Linux-Befehle, Networking-Basics, Cloud-Konzepte. Die Struktur war klar und das Tempo hoch. Jeden Tag neue Themen, neue Tools, neue Begriffe.

Ich habe in den ersten Wochen viel mit Tutorials und Labs gearbeitet -- verschiedene Anbieter, verschiedene Plattformen. Das hat funktioniert, um die Grundlagen zu verstehen: `ls`, `cd`, `chmod`, erste AWS-Services, was eine VPC ist oder was ein Load Balancer eigentlich macht.

Aber irgendwann merkt man: Tutorials zeigen dir die perfekte Welt. Schritt für Schritt, alles funktioniert, kein Fehler. Das echte Lernen beginnt erst da, wo Dinge schiefgehen und Probleme auftauchen, die nicht im Tutorial stehen.

---

### Lernen, um weiterzukommen

Juni 2025: AWS Cloud Practitioner bestanden. Das war der erste echte Meilenstein. IAM, VPC, S3, EC2 -- nicht nur als Begriffe, sondern als Services, deren Zusammenspiel langsam greifbar wurde.

Juli 2025: Linux Essentials bestanden. Kommandozeile, Dateisystem, Paketmanagement, grundlegende Administration. Die Sicherheit, sich auf einem Linux-System bewegen zu können, ohne bei jedem Befehl nachschlagen zu müssen.

Beide Zertifizierungen waren eine Mischung aus Kursarbeit und Selbststudium. Der Kurs hat die Grundlage gelegt -- die Tiefe kam erst durch eigenes Ausprobieren.

Zertifizierungen zeigen Wissen. Erfahrung beginnt erst, wenn man etwas Eigenes baut.

---

### Von Wissen zu Können

Ausgangspunkt war ein Dashboard-Mockup, das nach konkreten Stakeholder-Anforderungen umgesetzt wurde -- ein kompaktes Übungsprojekt vom Entwurf bis zur Präsentation.

Ich habe das Projekt weitergeführt. Das Dashboard lokal zum Laufen zu bringen war das eine -- aber ich wollte wissen, wie ich es in die Cloud bekomme.

Also habe ich es auf AWS mit ECS deployed: ein Dockerfile gebaut, das Image nach ECR gepusht, den ECS-Task konfiguriert und den Service gestartet. Mein erster echter Kontakt mit Containern und Cloud-Deployments -- kein Lab-Szenario, sondern mein eigenes Projekt.

Es hat funktioniert. Und genau in diesem Moment hat sich etwas verändert. Ab diesem Punkt habe ich bewusst nach Möglichkeiten gesucht, Theorie in eigene Infrastruktur zu überführen.

---

### Der erste eigene Stack

Das Dashboard lief auf ECS -- aber in der Sandbox-Umgebung der Weiterbildung. Abhängig von Kostenlimits, nicht dauerhaft verfügbar. Ich wollte das anders.

Also habe ich für kleines Geld einen Hetzner-Cloud-Server aufgesetzt. Ubuntu installiert, Docker eingerichtet, Services mit Docker Compose betrieben, eine Domain registriert und DNS konfiguriert.

Das war ein völlig anderes Lernen als das ECS-Deployment. Auf einem eigenen Server bist du für alles verantwortlich: Betriebssystem, Updates, Firewall, Netzwerk, Backups. Wenn etwas nicht läuft, gibt es keinen Managed Service, der das Problem für dich löst.

---

### Weniger Theorie, mehr eigenes Setup

Zwei Zertifizierungen. Ein Projekt, das sowohl auf AWS als auch auf eigener Infrastruktur lief. Erste Erfahrungen mit Containern, Deployments, Domains und selbst betriebener Infrastruktur.

Und die Erkenntnis: Lernen funktioniert für mich am besten, wenn ich etwas Echtes baue und betreibe.

Der nächste Schritt kam fast zwangsläufig.',
  'Die ersten Monate drehten sich um Grundlagen: Was eigentlich hinter dieser vielzitierten Cloud steckt. Darauf folgten zwei Zertifizierungen, eine als Kursaufgabe entstandene Mockup-Idee, erste Versuche mit Containern -- und schließlich der Punkt, an dem aus Theorie eigene Infrastruktur wurde.',
  'published', false, 6, 1, 7,
  '2026-02-17T10:00:00Z'
);

-- Post 3: Blackbox kaputt: Vom Provider-Router zum eigenen Netzwerk
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Blackbox kaputt: Vom Provider-Router zum eigenen Netzwerk',
  'provider-router-umstieg-unifi',
  '### Am Limit des Provider-Routers

Zu diesem Zeitpunkt liefen bereits zwei zentrale Bausteine meiner Infrastruktur: ein Cloud-Server bei Hetzner und eine frisch eingerichtete Synology NAS. Zwei Systeme, die miteinander kommunizieren sollten -- und ein Heimnetzwerk, das dafür plötzlich deutlich flexibler sein musste.

Der Telekom-Router war dafür allerdings kaum geeignet. Ein geschlossenes System mit stark eingeschränkten Konfigurationsmöglichkeiten. Für normale Internetnutzung vollkommen ausreichend -- aber sobald mehrere Systeme miteinander sprechen sollen, stößt man schnell an Grenzen.

Genau dieser Moment wurde zum Wendepunkt. Statt mich weiter innerhalb dieser Limits zu bewegen, fiel die Entscheidung: Wenn ich Infrastruktur verstehen will, dann auch das Netzwerk dahinter.

---

### UniFi: Mein Netzwerk, meine Regeln

Die Wahl fiel auf Ubiquiti UniFi -- Cloud Gateway Fiber, Access Point, Modem. Enterprise-Hardware, die in professionellen Umgebungen eingesetzt wird.

Der Unterschied war sofort spürbar. Plötzlich ließ sich das Netzwerk wirklich gestalten: Firewall-Regeln definieren, VLANs strukturieren, Traffic analysieren und nachvollziehen, wie Geräte miteinander kommunizieren.

Damit begann ein völlig neues Lernfeld. Subnetting, DNS, DHCP, Firewall-Regeln -- alles Themen, die auf dem Papier relativ schnell verstanden sind. Ein eigenes Netzwerk zu entwerfen, in dem mehrere Systeme stabil miteinander arbeiten, ist jedoch eine ganz andere Erfahrung.

Viele Dinge funktionieren erst nach mehreren Iterationen. Regeln greifen nicht wie erwartet, Services finden sich nicht im Netzwerk, Ports sind falsch gesetzt. Genau diese Momente sind es aber, in denen Infrastruktur wirklich verständlich wird.

---

### Mehr als nur Storage

Die NAS war von Anfang an als Infrastruktur-Plattform gedacht -- ein System, auf dem ich Container und Docker vertiefen kann, nicht nur Storage.

Container liefen dort dauerhaft, Backups wurden organisiert, Services zusammengeführt. Gleichzeitig wurde die NAS zum Ort, an dem ich ausprobieren konnte, wie sich Infrastruktur betreiben lässt: Updates, Monitoring, Netzwerkregeln, Zugriffskontrollen.

Mit NAS, Cloud-Server und dem neuen Netzwerk entstand nach und nach eine Umgebung, die deutlich mehr war als nur ein einzelner Server.

---

### Wenn Bausteine zusammenspielen

Je mehr Systeme dazu kamen, desto wichtiger wurde Übersicht.

Prometheus begann Metriken zu sammeln, Grafana visualisierte die Systeme, Dashy wurde zur zentralen Startseite für die Infrastruktur. Zum ersten Mal entstand ein Gefühl dafür, wie mehrere Services zusammen ein funktionierendes Gesamtsystem bilden.

Was zunächst als kleines Setup begann, entwickelte sich langsam zu einer Infrastruktur, die beobachtet, gepflegt und automatisiert werden musste.

---

### Automatisieren statt wiederholen

Mit wachsender Infrastruktur tauchten schnell Aufgaben auf, die sich ständig wiederholten. Statusmeldungen, kleine Datenbewegungen zwischen Systemen, Benachrichtigungen.

Hier kam n8n ins Spiel. Workflows auf der NAS verbanden Dienste miteinander, automatisierten Abläufe und nahmen viele kleine manuelle Schritte ab.

Ein weiterer Baustein in einer Umgebung, die immer stärker zusammenwuchs.

---

### Cloud nutzen, Homelab verantworten

Rückblickend war der Aufbau des Homelabs einer der wichtigsten Schritte dieser Phase.

In der Cloud lernt man, Services zu nutzen.  
Im Homelab lernt man, Infrastruktur zu betreiben.

Genau diese Kombination hat den weiteren Weg geprägt.',
  'NAS bestellt, Hetzner-Server lief schon -- aber der Telekom-Router ließ sich kaum konfigurieren. Das war der Punkt, an dem ich mein eigenes Netzwerk aufgebaut habe. Wie aus den Limitierungen eines Consumer-Routers Schritt für Schritt ein vollwertiges Homelab entstanden ist.',
  'published', false, 6, 1, 3,
  '2026-02-19T10:00:00Z'
);

-- Post 4: Sichere Infrastruktur von Tag 1: VPN, Reverse Proxy und Netw...
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Sichere Infrastruktur von Tag 1: VPN, Reverse Proxy und Networking in der Praxis',
  'sichere-infrastruktur-vpn-reverse-proxy',
  '### Die zentrale Frage: Wie wird das produktionsreif?

NAS läuft, Hetzner-Server läuft, erste Services sind deployed. Aber jetzt stellt sich die praktische Frage: Wie kommunizieren diese Systeme sicher miteinander? Wie komme ich von unterwegs auf meine Dienste? Und wie mache ich Services erreichbar, die erreichbar sein sollen -- ohne alles offen ins Internet zu stellen?

Das waren Fragen, die ich zu dem Zeitpunkt nicht theoretisch beantworten konnte. Ich musste es praktisch ausprobieren.

---

### WireGuard: Theorie gut, Praxis fragil

Mein erster Gedanke war WireGuard -- ein modernes VPN-Protokoll, das in meiner Recherche immer wieder als schnelle und sichere Lösung aufkam. Die Idee: einen verschlüsselten Tunnel zwischen NAS und Server aufbauen, damit ich von überall sicher auf meine Dienste zugreifen kann.

In der Praxis bin ich damit auf der Synology NAS nicht weit gekommen. WireGuard ist dort nicht nativ im VPN-Server-Paket enthalten. Was es gibt, sind Drittanbieter-Pakete und Docker-basierte Lösungen -- aber die sind fragil. DSM-Updates können das Kernel-Modul brechen, die Installation ist abhängig von der Hardware-Architektur, und insgesamt war das eine ziemlich frickelige Angelegenheit. Ich habe einige Zeit damit verbracht und keine stabile Lösung hinbekommen.

---

### Tailscale: Das richtige Tool für den Job

Bei der weiteren Recherche bin ich auf Tailscale gestoßen. Tailscale basiert auf WireGuard und nutzt das gleiche Protokoll für die Verschlüsselung. Der entscheidende Unterschied: Tailscale ist nativ im Synology-Paketzentrum verfügbar. Kein Drittanbieter-Paket, kein Docker-Workaround, keine Angst vor dem nächsten DSM-Update.

Installation auf der NAS, auf dem Server, auf meinem MacBook -- und plötzlich waren alle Geräte im gleichen verschlüsselten Netzwerk. Ich konnte von unterwegs auf meine NAS zugreifen, ohne einen einzigen Port zu öffnen. Der Server und die NAS konnten sicher miteinander kommunizieren.

Das war der Moment, in dem ich verstanden habe: Manchmal ist die Lösung nicht, sich durch eine komplizierte Einrichtung zu kämpfen, sondern das richtige Tool für den Job zu finden. WireGuard ist ein großartiges Protokoll -- aber Tailscale hat es für mein Setup erst praktisch nutzbar gemacht.

---

### Reverse Proxy: Von IP:Port zu Subdomains

Mit Tailscale war die interne Kommunikation gelöst. Aber manche Services auf dem Hetzner-Server sollten auch öffentlich erreichbar sein -- n8n, das agra-dashboard, später Grafana. Nicht über IP-Adresse und Portnummer, sondern über saubere Subdomains mit HTTPS.

Reverse Proxies waren für mich zu diesem Zeitpunkt komplettes Neuland. Mein erster Ansatz war Nginx Proxy Manager -- eine grafische Oberfläche, in der man Proxy-Hosts anlegt, SSL-Zertifikate verwaltet und Traffic weiterleitet. Das hat funktioniert und mir erstmal gezeigt, was ein Reverse Proxy überhaupt tut.

Nach weiterer Recherche und einer Empfehlung bin ich dann auf Traefik gestoßen. Ein anderer Ansatz: Statt grafischer Oberfläche wird alles über Labels in der Docker-Compose-Konfiguration gesteuert. Traefik erkennt Container automatisch und kümmert sich selbstständig um Let''s-Encrypt-Zertifikate.

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.n8n.rule=Host(`n8n.meinedomain.tech`)"
  - "traefik.http.routers.n8n.tls.certresolver=le"
```

Services über Subdomains erreichbar, mit gültigen Zertifikaten -- das Grundprinzip war verstanden.

---

### Networking lernt man durch Debugging

Das klingt im Rückblick alles strukturiert. War es nicht. Ich war ungeduldig, wollte Ergebnisse sehen, habe Dinge eingerichtet, die nicht beim ersten Mal funktioniert haben -- und habe dabei mehr über Networking gelernt, als ich erwartet hätte.

DNS-Einträge, SSL-Zertifikate, wie Subdomains funktionieren, was ein Reverse Proxy eigentlich tut -- das alles waren keine abstrakten Konzepte mehr, sondern Dinge, die ich anfassen und testen konnte.

Wenn ein Service nicht erreichbar war, musste ich debuggen: Liegt es am DNS? Am Zertifikat? Am Routing? An der Firewall? Dieses Troubleshooting hat mir mehr beigebracht als jede Networking-Theorie.

---

### Die Architektur, die sich ergeben hat

Durch das Ausprobieren hat sich Stück für Stück eine Architektur entwickelt:

- **Tailscale** als VPN-Schicht für die interne Kommunikation zwischen allen Systemen
- **Reverse Proxy** für Services, die öffentlich erreichbar sein sollen
- **Klare Trennung**: Interner Traffic läuft über das VPN, externer Traffic über den Reverse Proxy

Das war kein Masterplan, den ich am Anfang auf ein Whiteboard gezeichnet habe. Es war das Ergebnis von viel Ausprobieren, einigen Sackgassen und der Bereitschaft, Lösungen wieder zu verwerfen, wenn es eine bessere gibt.

---

### Lernen durch Sackgassen

Diese Phase hat mir gezeigt, dass Networking eines dieser Themen ist, die man nur durch praktisches Arbeiten wirklich versteht. Die Theorie gibt dir die Begriffe. Die Praxis gibt dir das Verständnis.

WireGuard hat nicht funktioniert -- also Tailscale.  
Nginx war ein guter Start -- Traefik ein weiterer Schritt.

Das ist kein Scheitern. Das ist Lernen.',
  'NAS und Hetzner-Server standen -- aber wie verbinde ich sie sicher miteinander? Erst WireGuard, dann Tailscale. Erst Nginx, dann Traefik. Viel ausprobiert, vieles verworfen, dabei mehr Networking gelernt als jedes Tutorial vermittelt.',
  'published', false, 6, 1, 4,
  '2026-02-21T10:00:00Z'
);

-- Post 5: Sandbox kaputt, alles weg -- wie ich Terraform lieben gelern...
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Sandbox kaputt, alles weg -- wie ich Terraform lieben gelernt habe',
  'sandbox-reset-terraform',
  '### Wenn plötzlich alles weg ist

Das Wochenende war produktiv gewesen. Lambda-Funktionen, DynamoDB, S3, CloudFront -- die Architektur stand. Am Sonntagabend lief alles so, wie ich es mir vorgestellt hatte.

Montagmorgen war davon nichts mehr übrig.

Die Sandbox-Umgebung der Weiterbildung hatte über Nacht einen automatischen Cleanup durchgeführt. Kostenlimit überschritten, Umgebung zurückgesetzt -- alles gelöscht.

Der erste Moment war Frust. Ein ganzes Wochenende Arbeit verschwunden.

Der zweite Gedanke war wichtiger: Wenn Infrastruktur einfach verschwinden kann, darf ihr Zustand nicht nur in einer laufenden Umgebung existieren.

---

### Der Mindshift

Bis zu diesem Punkt hatte ich Infrastruktur eher schrittweise aufgebaut. Services konfigurieren, Ressourcen anlegen, Dinge ausprobieren, erweitern.

Das funktioniert -- solange nichts kaputtgeht.

Sobald jedoch eine komplette Umgebung verschwindet, zeigt sich ein anderes Problem: Wissen steckt plötzlich nur noch im Kopf oder in einzelnen Konfigurationsschritten.

Die eigentliche Frage wurde deshalb schnell klar:

Wie baue ich Infrastruktur so, dass sie jederzeit wiederhergestellt werden kann?

---

### Terraform früher als geplant

Terraform stand zu diesem Zeitpunkt erst später auf dem Lehrplan der Weiterbildung. Der Sandbox-Wipe war für mich der Auslöser, mich schon vorher damit zu beschäftigen.

Ich begann, die EcoKart-Infrastruktur Schritt für Schritt in Terraform nachzubauen. Erst einzelne Ressourcen, dann komplette Services. Dinge, die vorher manuell entstanden waren, wanderten nach und nach in Code.

Das erste Mal `terraform apply` auf eine größere Konfiguration auszuführen und zu sehen, wie komplette Infrastruktur automatisch entsteht, war ein echter Aha-Moment.

Plötzlich ging es nicht mehr darum, eine Umgebung einmal aufzubauen -- sondern sie jederzeit reproduzieren zu können.

---

### SCP-Limitierungen: Tod durch tausend Freischaltungen

EcoKart wuchs -- und damit kamen neue Probleme. Allerdings nicht technische, sondern organisatorische.

Die Sandbox-Umgebung war durch Service Control Policies eingeschränkt. Bestimmte AWS-Services oder Features waren schlicht gesperrt.

Am Anfang war das noch okay. Aber je weiter das Projekt kam, desto öfter bin ich gegen diese SCP-Wände gelaufen.

ACM-Zertifikate? Gesperrt.  
Custom Domains? Gesperrt.

Der Ablauf war immer derselbe: Anfrage beim Dozenten, erklären warum ich den Service brauche, warten auf Freischaltung. Kaum war eine Limitierung aufgehoben, kam die nächste.

Irgendwann hatte ich das Gefühl, mehr Zeit damit zu verbringen, Freischaltungen zu organisieren als tatsächlich am Projekt zu arbeiten.

---

### Custom Domains: Der Auslöser

Der konkrete Punkt, an dem ich die Entscheidung getroffen habe, war die Stripe-Anbindung.

Ein Webshop braucht eine Zahlungsabwicklung, und Stripe war die logische Wahl. Das Problem: Stripe benötigt stabile Webhook-URLs und Endpoints. In der Sandbox haben sich diese bei jedem Redeploy verändert.

Gleichzeitig wurde mir klar: Das betrifft nicht nur Stripe.

Auch der Webshop selbst, der Adminbereich und die API liefen über rotierende URLs, die sich bei jedem Deployment änderten. Mit Custom Domains würde das alles hinter stabilen, gleichbleibenden Adressen verschwinden.

Keine angepassten Endpoints mehr. Keine wechselnden URLs.

Dafür brauchte ich Custom Domains -- und die wiederum brauchten eine SCP-Freischaltung.

An diesem Punkt war klar: Das ergibt keinen Sinn mehr. Ich brauche einen eigenen AWS-Account.

---

### Eigener Account, eigene Verantwortung

Die Entscheidung war bewusst.

Mir war klar, dass ich den gesamten Projektstand migrieren musste -- neue AWS Credentials, neue Endpoints, Anpassungen an mehreren Stellen.

Aber genau das war es mir wert.

Ein eigener Account bedeutete: keine SCP-Limitierungen mehr, eigene Kostenverantwortung und vor allem die Möglichkeit, ohne Freischaltungen weiterzulernen.

Und weil EcoKart inzwischen vollständig in Terraform definiert war, war die Migration machbar.

Neuer Account, neue Credentials konfigurieren, `terraform apply` -- und die Infrastruktur stand.

Nicht alles war eins zu eins übertragbar. Es gab Anpassungen. Aber die Grundstruktur war da -- und das war der Moment, in dem sich die Investition in Terraform zum ersten Mal wirklich ausgezahlt hat.

---

### CI/CD: Alles automatisieren

Der nächste logische Schritt war Automatisierung.

Ich wollte nicht jedes Mal lokal `terraform plan` und `terraform apply` ausführen.

CI/CD-Pipelines standen erst später auf dem Lehrplan der Weiterbildung. Ich hatte jedoch schon vorher begonnen, mir mit kleinen Skripten wiederkehrende Schritte zu automatisieren. Der Wunsch, das sauberer zu lösen, war also längst da.

Also habe ich mich in GitHub Actions eingearbeitet und eine richtige CI/CD-Pipeline aufgebaut.

Push auf den Main Branch, Pipeline läuft, Infrastruktur wird deployed. Später kamen noch Security-Checks hinzu, die bei jedem Push automatisch ausgeführt werden.

```
git push
↓
GitHub Actions
↓
terraform plan
↓
terraform apply
↓
live
```

Kein manuelles Deployment mehr. Kein „hab ich vergessen auszuführen“. Alles automatisiert, alles nachvollziehbar.

---

### Reproduzierbar statt einmalig

Mit der Zeit wuchs das Projekt weiter.

15 Terraform-Module.  
12 AWS-Services.  
63 Integrationstests.

Die komplette Infrastruktur ließ sich jederzeit neu aufbauen -- und kostete im Dauerbetrieb ungefähr 10 USD pro Monat.

Rückblickend war der Sandbox-Wipe einer der wichtigsten Momente dieser Phase.

Er hat mich gezwungen, Infrastruktur nicht mehr als einmaliges Setup zu sehen, sondern als System, das vollständig beschrieben und jederzeit reproduziert werden kann.

Terraform wurde dadurch zu einem zentralen Werkzeug in meinem Setup.',
  'Ein Wochenende Arbeit am EcoKart-Webshop, Montagmorgen alles gelöscht. Ein automatischer Cleanup-Workflow in der Sandbox-Umgebung hat jeden Fortschritt entfernt. Der Moment war frustrierend -- aber wichtiger war die Frage danach: Wie baut man Infrastruktur so, dass sie jederzeit reproduzierbar ist?',
  'published', false, 6, 1, 2,
  '2026-02-24T10:00:00Z'
);

-- Post 6: EcoKart: Mein erster vollständiger Webshop auf AWS
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'EcoKart: Mein erster vollständiger Webshop auf AWS',
  'ecokart-webshop-aws',
  '### Von Kostenvergleich zu eigenem Shop

Der Anstoß für EcoKart kam aus einer Gruppenarbeit in der Weiterbildung. Die Aufgabe war rudimentär: verschiedene Infrastruktur-Ansätze gegenüberstellen -- Serverless vs. EC2, managed vs. self-hosted -- und bewerten, welche Architektur für welche Anforderung sinnvoll ist. Welche Kosten entstehen, welche Vor- und Nachteile gibt es. Rein theoretisch, ohne Umsetzung.

Aber die Recherche hat etwas ausgelöst. Ich habe mir die verschiedenen Architekturen angeschaut und gedacht: Wie lerne ich das wirklich, wenn ich es nie umsetze? Wie verstehe ich AWS-Services in der Praxis, wenn ich nur Tabellen mit Kostenvergleichen fülle?

Also habe ich mir einen konkreten Use Case gesucht: einen vollständig serverlosen Webshop. Mit dem Ziel, die geringstmöglichen Kosten zu verursachen und trotzdem alles mitzubringen, was ein echter Shop braucht -- Produkte, Warenkorb, Zahlungsabwicklung, Benutzerverwaltung, Bestellbestätigung per Email. Von Anfang an als Showcase für spätere Bewerbungen gedacht. Nicht als Kursaufgabe, sondern als echtes Lernprojekt.

---

### Die Architektur

Serverless war gesetzt. Kein EC2, kein dauerhaft laufender Server. Stattdessen: AWS Lambda für die gesamte Backend-Logik, DynamoDB als Datenbank, API Gateway als Schnittstelle, Amplify für das Frontend. Dazu S3 und CloudFront für Produktbilder, Cognito für die Authentifizierung, Route53 für Custom Domains, ACM für SSL-Zertifikate, CloudWatch für Monitoring.

12 AWS-Services insgesamt, verteilt auf 15 Terraform-Module. Die monatlichen Kosten: ungefähr 10 bis 15 Dollar. Das war einer der entscheidenden Punkte für Serverless -- man zahlt nur, was man tatsächlich nutzt. Kein Leerlauf, keine Grundgebühr für laufende Instanzen. Genau das, was ich in der Gruppenarbeit theoretisch verglichen hatte, konnte ich jetzt in der Praxis bestätigen.

Die gesamte Infrastruktur ist in Terraform definiert. Jedes Modul hat seine eigene Verantwortung -- Cognito, DynamoDB, Lambda, Amplify, und so weiter. Ich kann den kompletten Shop in etwa 15 Minuten von Null aufbauen. Oder in Minuten zerstören und neu deployen.

---

### OIDC: Keine Keys im Repository

Eine Sache hat mich gestört: Jedes Mal, wenn ich eine Änderung am Frontend gepusht habe, musste ich den Build auf Amplify manuell auslösen. Das entsprach nicht meinen Erwartungen an Automatisierung -- aber ich war selbst noch im Prozess zu verstehen, wie das eigentlich richtig funktioniert.

Recherche und ein Gespräch mit meinem Dozenten brachten mich auf OIDC -- OpenID Connect. Die Idee: GitHub Actions authentifiziert sich direkt bei AWS, ohne dass langlebige Access Keys irgendwo hinterlegt werden müssen. Stattdessen bekommt jeder Workflow-Run temporäre Credentials, die nach einer Stunde automatisch ablaufen.

```yaml
- name: Configure AWS Credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: eu-central-1
```

Kein einziger AWS-Key im Repository. Push auf den Branch, GitHub Actions übernimmt, Terraform deployed. Keine manuellen Schritte mehr.

---

### Cognito: Authentifizierung, die sich gewehrt hat

Für die Benutzerverwaltung habe ich mich für AWS Cognito entschieden. Die Idee war einfach: Benutzer registrieren sich, bestätigen ihre Email, bekommen ein JWT-Token und authentifizieren sich damit bei der API.

Die Umsetzung war alles andere als einfach. Cognito hat viele Stellschrauben, und die Dokumentation ist nicht immer intuitiv. Token-Handling, Refresh-Logik, Custom Attributes für Rollen, Email-Verifizierung mit sechsstelligen Codes -- jedes dieser Themen war eine eigene Baustelle.

Am Ende funktioniert es: Registrierung, Login, rollenbasierter Zugriff und ein Admin-Dashboard. Aber es war die aufwendigste Lernkomponente des gesamten Projekts.

---

### Stripe: Stabile Endpoints erzwingen

Für die Zahlungsabwicklung habe ich Stripe integriert. Der Kunde wird zum Checkout weitergeleitet, gibt seine Kartendaten ein und nach erfolgreicher Zahlung schickt Stripe einen Webhook an meine Lambda-Funktion. Die erstellt die Bestellung in DynamoDB.

Ein Problem blieb lange bestehen: Nach jedem `terraform destroy` und neuem Deploy bekam die API einen neuen Endpoint. Damit war die Webhook-URL bei Stripe jedes Mal kaputt.

Die Lösung waren Custom Domains über Route53 und ein ACM-Zertifikat. Damit blieb der Stripe-Endpoint stabil, egal wie oft ich die Infrastruktur neu aufgebaut habe. Gleichzeitig liefen auch Webshop, Adminbereich und API unter festen URLs.

---

### Email-Odyssee: Neujahr bei Resend

Ein Webshop ohne Bestellbestätigung per Email ist kein richtiger Webshop. AWS SES war der naheliegende Weg.

Im Sandbox-Modus funktionierte SES auch, aber für echte Nutzer braucht man den Production-Modus. Antrag gestellt. Abgelehnt. Also ein externer Anbieter: SendGrid. Ebenfalls abgelehnt.

Zwei Ablehnungen hintereinander, und ich konnte das Problem erst nicht greifen. Irgendwann habe ich verstanden, woran es liegt: Sowohl AWS als auch SendGrid sind bei ganz neuen Accounts extrem vorsichtig. Kein Versand-Verlauf, kein Vertrauen. Das ist eine Spam-Schutzmaßnahme, die erst mal jeden trifft, der frisch anfängt.

Die Lösung kam am 1. Januar 2026. Neujahrsmorgen, und ich sitze an der Email-Integration. Ich hatte von Resend gehört -- ein neuerer Email-Service, der sich explizit an Entwickler richtet. Account erstellt, Domain verifiziert, API-Key generiert, Code angepasst. 90 Minuten später verschickte EcoKart die erste Bestellbestätigung.

Die Lektion: Nicht ewig kämpfen, sondern Alternativen evaluieren. Die Migration hat 90 Minuten gedauert. Das Warten auf die SES-Freischaltung hätte ewig dauern können.

---

### Testing

Ein Webshop, der Zahlungen verarbeitet und Benutzerdaten verwaltet, muss getestet sein.

63 Tests mit Jest, aufgeteilt in Unit- und Integrationstests. Was mir beim Testen am meisten gebracht hat, war das Denken in Fehlerfällen. Nicht nur "funktioniert der Warenkorb", sondern: Was passiert, wenn ein Nutzer versucht, die Bestellung eines anderen Nutzers abzurufen? Die Antwort muss ein 403 sein, kein 404 -- weil der Nutzer wissen soll, dass die Ressource existiert, er aber keinen Zugriff hat. Solche Unterscheidungen lernt man erst, wenn man sie tatsächlich testet.

Die Integrationstests laufen über LocalStack -- eine lokale Emulation von AWS-Services. Damit kann ich den kompletten Flow testen: Produkt in den Warenkorb, Bestellung auslösen, prüfen ob der Lagerbestand korrekt reduziert wurde, über alle vier DynamoDB-Tabellen hinweg. Kein Mocking, sondern echte Datenbankoperationen.

In der CI/CD Pipeline laufen die Tests automatisch bei jedem Push. Kein Deployment ohne grüne Tests.

---

### Was ein eigenes Projekt wirklich lehrt

EcoKart hat mir mehr über AWS beigebracht als jeder Kurs. Nicht weil der Kurs schlecht wäre -- sondern weil ein eigenes Projekt Probleme erzeugt, die in keinem Tutorial stehen.

12 AWS-Services. 15 Terraform-Module. Ein Shop, der Bestellungen annimmt, Zahlungen verarbeitet, Bestätigungen verschickt und sich in etwa 15 Minuten vollständig reproduzieren lässt.

Das ist kein Kursprojekt mehr. Das ist Praxiserfahrung.',
  'Ein Kurs-Rechercheprojekt über Infrastruktur-Kosten brachte mich auf die Idee, einen echten Webshop auf AWS zu bauen. 12 Services, 15 Terraform-Module, Stripe-Zahlungen, Cognito-Authentifizierung -- und eine Email-Provider-Odyssee, die mich am Neujahrstag bei Resend landen ließ.',
  'published', true, 7, 1, 1,
  '2026-02-26T10:00:00Z'
);

-- Post 7: Das große Bild: Wie aus einzelnen Projekten eine Hybrid-Infr...
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Das große Bild: Wie aus einzelnen Projekten eine Hybrid-Infrastruktur mit über 50 Services wurde',
  'hybrid-infrastruktur-50-services',
  '### Vor einem Jahr existierte nichts davon

Wenn ich heute auf mein Homelab schaue, sehe ich etwas, das vor einem Jahr nicht existiert hat: drei Standorte, über 50 containerisierte Services, ein zentrales Monitoring, automatisierte Daten-Pipelines und ein Dashboard, von dem aus ich alles erreiche.

Das war nie so geplant. Es ist organisch gewachsen -- Stück für Stück, Service für Service, Problem für Problem. Jedes Mal, wenn ich etwas Neues lernen wollte, habe ich es in die bestehende Infrastruktur integriert. Irgendwann war es keine Spielerei mehr, sondern eine echte Plattform.

---

### Drei Standorte, eine Verbindung

Die Infrastruktur verteilt sich auf drei Standorte:

**Die NAS zuhause** -- eine Synology DS925+ mit 32 GB RAM. Sie ist das Herzstück: zentrales Storage, Monitoring-Hub, eigenes GitLab, Wazuh SIEM als Security-Zentrale. Alles, was Daten langfristig speichern oder zentral auswerten muss, läuft hier.

**Ein Cloud-Server in Deutschland** -- klein, ressourcenschonend, ARM-basiert. Hier laufen Web-Anwendungen wie n8n für Automatisierung sowie Traefik als Reverse Proxy mit TLS-Terminierung. Services, die von außen erreichbar sein müssen, aber wenig Rechenleistung brauchen.

**Ein zweiter Cloud-Server** -- deutlich leistungsstärker, mit 16 vCPUs und 32 GB RAM. Hier laufen datenintensive Workloads: automatisierte Pipelines, die Daten verarbeiten, verifizieren und zwischen Standorten synchronisieren. Dazu Shell-Skripte und Cronjobs in regelmäßigen Intervallen.

Verbunden ist alles über Tailscale. Kein Port Forwarding, keine öffentlich exponierten Services. Jeder Server, jedes Gerät -- auch meine beiden MacBooks -- hängt im selben verschlüsselten Mesh-Netzwerk. Wenn ich von unterwegs auf Grafana oder Portainer zugreifen will, geht das über die Tailscale-IP. Ohne VPN-Client starten zu müssen, ohne Tunnel manuell aufzubauen. Es funktioniert einfach.

---

### Logik hinter der Verteilung

Die Entscheidung, welcher Service wo läuft, folgt einer einfachen Logik:

**Rechenintensiv und datengetrieben** kommt auf den leistungsstarken Server. Dort stehen genug CPU-Ressourcen und schnelle NVMe-SSDs für I/O-intensive Workloads zur Verfügung. Automatisierte Pipelines verarbeiten Daten, verifizieren die Integrität und synchronisieren sie per rsync auf eine externe Storage Box. Von dort zieht die NAS die Daten über Cloud Sync. Mehrstufig, mit Prüfungen auf jeder Ebene.

**Web-Anwendungen und öffentliche Endpunkte** laufen auf dem kleinen Server. n8n für Webhook-basierte Automatisierung, Traefik für TLS -- das braucht wenig Leistung, aber eine stabile öffentliche IP und saubere Zertifikatsverwaltung.

**Alles Zentrale** bleibt auf der NAS. Prometheus sammelt Metriken von allen Standorten. Grafana visualisiert sie. Wazuh aggregiert Security-Events. GitLab hostet meine privaten Repositories. Die NAS ist die einzige Komponente, die nicht in der Cloud läuft -- und das ist bewusst so. Hier liegen die Daten, hier laufen die Auswertungen, hier ist die Kontrolle.

---

### Automatisierung: Wo die echte Arbeit steckt

Was mich am meisten überrascht hat: Die eigentliche Arbeit steckt nicht im Aufsetzen der Services, sondern in der Automatisierung drumherum.

Auf dem leistungsstarken Server laufen mehrere Cronjobs in unterschiedlichen Intervallen -- von minütlicher Datenverarbeitung bis zu täglichen Cleanup-Routinen. Ein Safety-Net-Skript erkennt hängengebliebene Prozesse und bereinigt sie automatisch.

Das Sync-Skript allein hat über 250 Zeilen. Es synchronisiert Ordner einzeln, vergleicht Dateianzahlen zwischen Quelle und Ziel, löscht erst nach Bestätigung, überwacht den Festplattenspeicher und pausiert Prozesse automatisch, wenn weniger als 20 GB frei sind. Kein einfaches `rsync -r` und hoffen, dass es passt -- sondern mehrstufige Verifikation mit Logging.

Shell-Skripte und Cron klingen nicht glamourös. Aber diese Skripte laufen seit Wochen zuverlässig -- und genau daran habe ich Fehlerbehandlung, Robustheit und die Realität von Automatisierung wirklich verstanden.

---

### Monitoring: Von Anfang an mitgedacht

Monitoring war kein Nachgedanke -- es ist gemeinsam mit der Infrastruktur gewachsen. Von Prometheus und Grafana auf dem ersten Server bis hin zu einem mehrstufigen System mit Uptime Kuma für Verfügbarkeit und Wazuh als SIEM für Security-Events. Jede Erweiterung hatte einen konkreten Auslöser, und jede hat sich bewährt.

Wie das im Detail aussieht, welche Entscheidungen dahinter stecken und warum sich der frühe Start konkret ausgezahlt hat -- das ist eine eigene Geschichte.

---

### Dashy: Ein Dashboard für alles

Mein Einstiegspunkt in die gesamte Infrastruktur ist Dashy -- ein Self-Hosted Dashboard, das auf der NAS läuft. Darüber erreiche ich alles: Grafana-Dashboards, Portainer für Container-Management, Uptime Kuma, Wazuh, die Synology-Oberfläche, GitLab, meine Webseiten. Sogar die Philips Hue Lampen lassen sich darüber schalten.

Kein Wechseln zwischen Bookmarks, kein Merken von Ports und IPs. Ein Dashboard, alle Services, alle Standorte.

---

### GitLab: Private Repos, selbst gehostet

Neben GitHub für öffentliche Projekte betreibe ich ein eigenes GitLab auf der NAS. Dort liegen alle privaten Repositories -- Infrastruktur-Dokumentation, Konfigurationen, Skripte. Alles, was nicht öffentlich sein soll, aber trotzdem versioniert und nachvollziehbar sein muss.

GitLab läuft als Container auf der NAS und ist nur über Tailscale erreichbar. Kein öffentlicher Zugriff, keine Cloud-Abhängigkeit. Meine Daten, mein Server, meine Kontrolle.

---

### Organisch, aber bewusst

Nichts davon war geplant. Es gab keinen Architektur-Entwurf, kein Zieldiagramm. Ich wollte lernen, habe Services aufgesetzt, bin auf Probleme gestoßen, habe sie gelöst -- und plötzlich war da eine verteilte Infrastruktur mit über 50 Services.

Aber "organisch gewachsen" heißt nicht "unkontrolliert". Jeder Service hat seinen Platz, jede Entscheidung hat einen Grund. Monitoring läuft zentral, Security ist mehrstufig, Backups sind automatisiert, und jede Konfiguration ist in Git versioniert.

Angefangen mit Docker Compose, Shell-Skripten und Cronjobs -- und mit jedem neuen Service, jedem gelösten Problem ist die Infrastruktur und mein Verständnis mitgewachsen. Man wächst an seinen Aufgaben, und dieses Homelab war der beste Beweis dafür.',
  'NAS zuhause, zwei Cloud-Server an verschiedenen Standorten, verbunden über Tailscale. Über 50 containerisierte Services, verteilt nach Aufgabe und Ressourcenbedarf. Docker Compose, Shell-Skripte, Monitoring-Stack. Organisch gewachsen aus dem Wunsch, Dinge wirklich zu verstehen.',
  'published', false, 7, 1, 3,
  '2026-02-28T10:00:00Z'
);

-- Post 8: Monitoring und Security: Warum ich früh angefangen habe und ...
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Monitoring und Security: Warum ich früh angefangen habe und es sich ausgezahlt hat',
  'monitoring-und-security',
  '### Prometheus/Grafana: Die ersten Metriken

Auf meinem ersten kleinen Hetzner-Server habe ich Prometheus und Grafana aufgesetzt. Basis-Metriken: CPU, RAM, Festplatte. Dazu ein Link ins Dashy-Dashboard, damit ich das Grafana-Panel schnell erreiche. Mehr nicht.

Das war kein durchdachter Monitoring-Plan. Es war Neugier: Ich wollte sehen, was auf dem Server passiert. Rückblickend war genau diese Neugier der Anfang von allem, was danach kam -- weil sie eine Grundlage geschaffen hat, auf der ich immer weiter aufbauen konnte.

---

### Zentralisieren und erweitern

Mit dem zweiten Server und einer wachsenden Zahl von Services wurde klar: Basis-Metriken auf einem einzelnen Server reichen nicht mehr. Die NAS hatte zwar über DSM eigene Grundwerte, aber ich wollte alles an einem Ort sehen -- und vor allem Alerting einrichten, damit ich nicht ständig manuell nachschauen muss.

Also habe ich Prometheus auf die NAS verlegt und als zentrale Sammelstelle eingerichtet. Node Exporter auf jedem Server für Systemmetriken, cAdvisor für Container-Metriken, Custom Exporter für service-spezifische Daten. Alles über Tailscale, alles verschlüsselt. 16 Targets, die alle 15 Sekunden gescraped werden.

Grafana hat drei Dashboards bekommen: eins pro Server mit Detailmetriken und ein Multi-Server-Overview für den schnellen Blick auf alles. CPU, RAM, Disk, I/O und Netzwerk -- auf einen Blick, für alle Standorte. Alerts gehen direkt über Telegram: CPU über 90 %, RAM über 90 %, Disk über 80 % oder wenn ein Service nicht mehr erreichbar ist.

Gleichzeitig kamen Uptime Kuma und Portainer dazu. Uptime Kuma überwacht 12 Services im 60-Sekunden-Takt -- per HTTP-Check, TCP-Check oder Ping. Das ergänzt genau die Perspektive, die Prometheus nicht abdeckt: Ist der Service aus Nutzersicht erreichbar? Auch hier gehen Alerts direkt auf Telegram.

---

### Bestätigung durch den Ernstfall

Dass sich dieses Setup bewährt, habe ich relativ früh erfahren. Einmal nachts unterwegs, mit einem Laptop, der nicht auf mein gewohntes Setup abgestimmt war -- weil ich alles ursprünglich über mein anderes MacBook konfiguriert hatte.

Die Telegram-Benachrichtigungen haben mich sofort erreicht, und ich konnte das Problem remote eingrenzen und entschärfen.

Das war kein Worst-Case-Szenario. Es war der Moment, der bestätigt hat: Monitoring und Alerting funktionieren genau so, wie sie sollen -- auch wenn die Umstände nicht ideal sind.

Was danach folgte, war keine Panikreaktion, sondern eine bewusste Weiterentwicklung. Der betroffene Server wurde komplett neu aufgesetzt, und dabei habe ich das Security-Setup deutlich verschärft:

- Docker-Daemon auf `127.0.0.1` gebunden, damit Container nicht versehentlich auf öffentlichen IPs lauschen  
- UFW-Firewall aktiviert, nur die Ports offen, die wirklich benötigt werden  
- fail2ban für SSH-Schutz mit automatischem Ban nach drei Fehlversuchen  
- Alle internen Services ausschließlich über Tailscale erreichbar

Dazu kam die proaktive Seite: Watchtower aktualisiert Docker-Container automatisch zu festen Zeiten. Auf den Servern laufen Unattended-Upgrades für Kernel- und Security-Patches, inklusive automatischer Reboots. Jeden Tag kommt eine Telegram-Benachrichtigung, dass die Updates sauber durchgelaufen sind.

Kein manuelles Patchen, kein Vergessen -- alles automatisiert.

Security ist kein Zustand, den man einmal herstellt. Es ist ein Prozess, der sich mit jeder Erfahrung weiterentwickelt.

---

### Wazuh: Die Security-Lücke schließen

Prometheus und Uptime Kuma überwachen Performance und Verfügbarkeit. Aber Security-Events -- wer greift auf was zu, welche Container starten mit welchen Rechten oder ob jemand versucht, sich per SSH einzuloggen -- decken sie nicht ab.

Durch Recherche und Austausch mit anderen Engineers bin ich auf Wazuh gestoßen -- ein Open-Source-SIEM, das genau diese Lücke schließt.

Also habe ich Wazuh auf der NAS aufgesetzt: Manager, Indexer und Dashboard. Auf beiden Cloud-Servern laufen Agents, die Events an den Manager melden. Docker-Listener überwachen Container-Aktivitäten in Echtzeit: `docker exec`-Befehle, Container mit Host-Netzwerk, Zugriffe auf den Docker-Socket oder privilegierte Container.

Die Events werden nach Severity klassifiziert. Alles ab Level 10 -- also potenziell sicherheitsrelevant -- wird direkt als Alert auf Telegram geschickt. Darunter wird lediglich geloggt. Das verhindert Alert-Fatigue: Ich werde nur gestört, wenn es wirklich relevant ist.

---

### Alle Wege führen zu Telegram

Über die Zeit hat sich ein dreistufiges Alerting-System entwickelt. Drei verschiedene Tools überwachen unterschiedliche Aspekte der Infrastruktur -- und alle Alerts landen im gleichen Kanal:

**Grafana** für Performance: CPU, RAM, Disk, Netzwerk. Die Metriken, die zeigen, ob die Infrastruktur unter Last steht.

**Uptime Kuma** für Verfügbarkeit: Services antworten nicht mehr, Latenzen steigen oder Zertifikate laufen ab. Die Nutzerperspektive.

**Wazuh** für Security: Fehlgeschlagene SSH-Logins, verdächtige Container-Aktivitäten oder Dateiänderungen in kritischen Verzeichnissen.

Alle drei melden an Telegram. Egal ob ich zuhause am Schreibtisch sitze oder unterwegs bin -- ich sehe sofort, was passiert und kann einschätzen, ob ich reagieren muss.

---

### Stück für Stück, nicht alles auf einmal

Ich möchte nicht den Eindruck erwecken, dass dieses Setup von Anfang an geplant war. Es war ein Prozess.

Erst Prometheus und Grafana, weil ich sehen wollte, was auf meinem Server passiert. Dann Uptime Kuma, weil Metriken allein nicht zeigen, ob ein Service wirklich erreichbar ist. Dann die Bestätigung, dass Alerting funktioniert -- und die Erkenntnis, dass Performance-Monitoring allein nicht reicht. Und schließlich Wazuh, weil Security eine eigene Überwachungsebene braucht.

Jede Erweiterung hatte einen konkreten Auslöser. Dieses Setup ist nicht aus einem Tutorial entstanden, sondern aus echten Anforderungen im Betrieb.

---

### Früh anfangen zahlt sich aus

Monitoring ist nicht optional. Es ist die Grundlage dafür, zu verstehen, was in der eigenen Infrastruktur passiert -- und rechtzeitig reagieren zu können, wenn etwas nicht stimmt.

Früh anfangen zahlt sich aus. Nicht weil man von Anfang an alles perfekt macht, sondern weil man eine Grundlage schafft, auf der man weiter aufbauen kann.

Mein erstes Grafana-Dashboard hatte drei Panels. Heute überwache ich damit drei Standorte. Der Unterschied ist nicht das Tool -- der Unterschied ist die Erfahrung, die dazwischen liegt.',
  'Prometheus und Grafana liefen schon auf meinem ersten Server. Was als einfaches Ressourcen-Monitoring begann, ist Stück für Stück zu einem mehrstufigen System gewachsen -- Uptime Kuma für Verfügbarkeit, Wazuh als SIEM für Security-Events, Telegram als zentraler Alarmkanal. Jede Erweiterung hatte einen konkreten Grund.',
  'published', false, 6, 1, 4,
  '2026-03-03T10:00:00Z'
);

-- Post 9: Crypto-Miner auf meinem Server: Wie ich den Angriff erkannt ...
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Crypto-Miner auf meinem Server: Wie ich den Angriff erkannt und gestoppt habe',
  'crypto-miner-nas-angriff-erkannt',
  '### NAS auf Maximum, Telegram vibriert

Ich sitze am Schreibtisch, die NAS steht eine Armlänge entfernt. Normalerweise ist sie kaum hörbar. Dann, von einer Sekunde auf die nächste, dreht sie komplett auf. Lüfter auf Maximum, ein Geräusch, das ich so noch nie gehört habe. Mein erster Gedanke: Da stimmt etwas nicht.

Gleichzeitig vibriert mein Handy. Telegram. Grafana-Alert: CPU-Auslastung über 200 Prozent. Mehrere Werte im kritischen Bereich.

---

### Ruhe bewahren, systematisch vorgehen

Kein Panik-Modus. Ich öffne das Grafana-Dashboard und sehe sofort: Die CPU-Last ist nicht graduell gestiegen, sondern schlagartig explodiert. Das ist kein normaler Workload. Das ist entweder ein defekter Container oder etwas, das dort nicht hingehört.

Also systematisch vorgehen: Welche Container laufen, welche Prozesse verursachen die Last, was hat sich in den letzten Stunden verändert? Der Scan zeigt schnell ein eindeutiges Bild. Ein Container, den ich etwa zwei bis drei Stunden vorher reaktiviert hatte, verursacht die gesamte Last.

Es war ein alter Blog-Container -- ein frühes Projekt aus den ersten Monaten meiner Weiterbildung, das ich nach längerer Pause wieder hochgefahren hatte, um an alte Inhalte zu kommen. In der Zwischenzeit hatte jemand eine offene Datenbankverbindung in diesem Container als Einstiegspunkt genutzt und einen Crypto-Miner gestartet. Die NAS rechnete mit voller Leistung für jemand anderen.

Container isoliert, gestoppt, entfernt. Unter drei Minuten von der ersten Meldung bis zur Entschärfung.

---

### Die Schwachstelle: Altlast aus der Lernphase

Die retrospektive Analyse hat gezeigt: Der Container stammte aus einer Phase, in der ich gerade erst angefangen hatte, mit Datenbanken zu arbeiten. Damals war in der MongoDB-Konfiguration ein Workaround für ein lokales Connection-Problem gesetzt worden -- eine Einstellung, die in der Entwicklungsumgebung funktioniert hat, aber nie für den Dauerbetrieb gedacht war.

Der Container war monatelang deaktiviert, das Projekt eingefroren, andere Prioritäten hatten übernommen. Als ich ihn Monate später reaktivierte, war die alte Datenbank-Konfiguration noch aktiv -- und innerhalb weniger Stunden hatte jemand sie gefunden.

Das Internet wird systematisch nach offenen Datenbanken gescannt. Wer eine ungesicherte Verbindung exponiert, wird gefunden. Nicht in Wochen, nicht in Tagen -- in Stunden.

---

### Bereinigung und Härtung

Nach der unmittelbaren Entschärfung habe ich das Ganze gründlich aufgearbeitet:

- Datenbank komplett abgesichert, Zugriff auf localhost beschränkt
- Sämtliche Credentials rotiert -- nicht nur die betroffenen, sondern alle
- Den alten Container und seine Konfiguration vollständig entfernt
- Alle laufenden Container auf ähnliche Altlasten geprüft

Am Ende stand die Gewissheit: Keine weiteren offenen Flanken, keine Spuren des Miners außerhalb des isolierten Containers. Der Angriff war auf diesen einen Container begrenzt -- und genau dort lag er auch keine drei Minuten später bereits still.

---

### Warum Monitoring den Unterschied macht

Das ist der eigentliche Punkt dieses Posts. Nicht der Angriff selbst -- sondern was davor bereits existierte.

Ich war zuhause und habe die NAS gehört. Aber was, wenn ich nicht zuhause gewesen wäre? Was, wenn das nachts passiert wäre oder unterwegs?

Genau dafür steht das Monitoring. Der Grafana-Alert wäre trotzdem gekommen. Auf Telegram, auf mein Handy, egal wo ich bin. Ich hätte den CPU-Spike gesehen, hätte mich remote über Tailscale verbinden können und hätte den Container auch von unterwegs stoppen können. Die Reaktionszeit wäre vielleicht nicht drei Minuten gewesen, aber es wären Minuten geblieben -- nicht Stunden oder Tage.

Ohne Alerting hätte der Miner möglicherweise so lange laufen können, bis die Hardware Schaden nimmt. Bei über 200 Prozent CPU-Auslastung und der Hitzeentwicklung, die ich in den Metriken gesehen habe, bin ich nicht sicher, wie lange die NAS das mitgemacht hätte.

Das Monitoring stand. Der Alert kam innerhalb von Sekunden. Und weil ich wusste, wo ich nachschauen muss -- Grafana für die Übersicht, Container-Metriken für die Eingrenzung -- war der Verursacher in Minuten identifiziert. Das ist der Return on Investment für jeden Service, den ich in den Monaten davor aufgesetzt habe.

---

### Lektionen für die Zukunft

**Alte Konfigurationen leben weiter.** Ein Container, der monatelang deaktiviert war, trägt seine Konfiguration mit. Wer einen alten Service reaktiviert, muss ihn vorher prüfen -- nicht nur ob er läuft, sondern ob er sicher ist. Das ist seitdem Standard bei mir.

**Das Netz vergisst nicht und schläft nicht.** Offene Datenbanken, exponierte Ports, ungesicherte Services -- sie werden aktiv und automatisiert gescannt. Wenige Stunden reichen.

**Ohne Monitoring bleibt ein Angriff unsichtbar.** Es ist die Grundlage dafür, dass man ihn in Minuten erkennt statt in Tagen.

**Strukturiertes Vorgehen zahlt sich aus.** Erkennen, eingrenzen, isolieren, bereinigen, aufarbeiten. Kein hektisches Abschalten, kein Neuinstallieren ohne Plan.

Rückblickend bin ich froh, dass es passiert ist. Nicht weil ein Angriff auf die eigene Infrastruktur erstrebenswert wäre -- sondern weil es die Bestätigung war, dass das Monitoring funktioniert, die Reaktion sitzt und der eingeschlagene Weg der richtige ist.

Das ist keine Theorie mehr. Das ist Praxis.',
  'Die NAS neben mir wird plötzlich ohrenbetäubend laut, Telegram meldet CPU-Auslastung über 200 Prozent. In unter drei Minuten war der Verursacher identifiziert und isoliert. Wie mein Monitoring-Stack einen echten Angriff erkannt hat -- und was schnelle Reaktion wirklich bedeutet.',
  'published', false, 6, 1, 4,
  '2026-03-05T10:00:00Z'
);

-- Post 10: AWS Solutions Architect: Warum ich die Prüfung mit Praxis st...
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'AWS Solutions Architect: Warum ich die Prüfung mit Praxis statt nur Theorie vorbereitet habe',
  'aws-solutions-architect-praxis',
  '### Solutions, nicht Services

Die Prüfung heißt Solutions Architect. Nicht Services Architect, nicht Infrastructure Architect. Solutions.

Als ich angefangen habe, mich mit den Prüfungsinhalten auseinanderzusetzen, habe ich etwas wiedererkannt: Anforderungen aufnehmen, Rahmenbedingungen verstehen, verschiedene Wege abwägen und die passende Lösung finden. In fast zwanzig Jahren Berufserfahrung war genau das mein Alltag -- egal ob es um Produkte, Kunden oder Prozesse ging. Die Herausforderung war immer die gleiche: Es gibt einen Rahmen, manchmal vorgegeben, manchmal offen, und innerhalb dieses Rahmens muss eine Lösung entstehen, die funktioniert.

Die Domäne ist eine andere. Aber die Denkweise war nicht neu. Und genau das hat mir in der Vorbereitung geholfen.

---

### Verstehen, nicht nur bestehen

Ich habe mir bewusst die Zeit genommen, die es braucht. Nicht um eine Prüfung zu bestehen, sondern um die Themen wirklich zu durchdringen. Vieles von dem, was die Prüfung abfragt, lässt sich nicht einfach im eigenen Account nachbauen: Multi-Account-Strategien für große Organisationen, Migrationen von Hunderten Servern oder Hybrid-Architekturen mit Direct Connect in Enterprise-Dimensionen.

Also habe ich genau das gemacht: recherchiert, Dokumentation und Whitepapers gelesen, Szenarien durchgespielt. Wann immer möglich, Labs integriert und Konzepte praktisch nachvollzogen. Nicht alles lässt sich hands-on abbilden -- aber der Anspruch war, auch rein theoretische Themen so zu verstehen, dass ich sie erklären und einordnen kann.

Parallel dazu lief die Praxis im eigenen AWS-Account weiter. VPC-Networking, IAM-Policies, S3-Konfigurationen, CloudFront -- alles Themen, die in der Prüfung vorkommen und die ich gleichzeitig in EcoKart live im Einsatz hatte. Diese Kombination aus theoretischer Breite und praktischer Tiefe war der Kern meiner Vorbereitung.

---

### Eigene Lernmaterialien

Was sich früh als wertvoll herausgestellt hat: Nicht nur konsumieren, sondern selbst aufbereiten. Interaktive Flashcards, Quizzes, Service-Vergleichskarten -- alles in eigenen Worten formuliert. Wenn ich ein Konzept erklären kann, habe ich es verstanden. Wenn nicht, muss ich nochmal tiefer einsteigen.

Dazu Hunderte Practice-Fragen mit eigenen Erklärungen versehen. Nicht als Wiederholung, sondern als Verständnisprüfung. Warum ist diese Antwort richtig? Warum sind die anderen falsch? Was ist das zugrundeliegende Prinzip?

Über die Zeit hat sich dabei ein Gespür entwickelt: AWS-Prüfungsfragen beschreiben komplexe Szenarien mit spezifischen Anforderungen -- Verfügbarkeit, Kosten, Compliance, Performance. Die Herausforderung liegt darin, aus dem Zusammenspiel dieser Anforderungen die architektonisch sinnvollste Lösung abzuleiten. Das ist keine Frage einzelner Services, sondern eine Frage der richtigen Kombination.

---

### Alle Szenarien, alle Plattformen

Practice Tests waren das härteste und ehrlichste Feedback. Mein Anspruch war klar: über mehrere Plattformen hinweg möglichst viele Fragen sehen und so viele Szenarien wie möglich durcharbeiten. Nicht um eine Quote zu erreichen, sondern um sicherzustellen, dass ich die Themen wirklich verstehe -- auch die, die sich nur theoretisch erarbeiten lassen.

Jede Plattform formuliert anders, setzt andere Schwerpunkte und beleuchtet andere Aspekte. Genau das wollte ich: kein plattformspezifisches Wissen, sondern ein Verständnis, das unabhängig von der Fragestellung trägt.

Die Fehleranalyse war dabei oft wertvoller als die richtige Antwort. Jede falsche Antwort wurde analysiert: Welches Konzept fehlt? Wiederholfehler oder neues Thema? Am Ende wollte ich mit dem sicheren Gefühl in die Prüfung gehen, dass ich die Breite der Themen durchdrungen habe -- nicht nur die, die ich praktisch kenne.

---

### Enterprise: Über das Homelab hinaus

Enterprise-Szenarien waren die größte Herausforderung. Hunderte VMs migrieren, Multi-Account-Strategien, Hybrid-Architekturen in einer Größenordnung, die mein Homelab nie abbilden kann. Das sind Themen, für die es keine echte Hands-on-Alternative gibt, wenn man keinen Enterprise-Kontext hat.

Gerade diese Themen haben mich am meisten weitergebracht. Sie haben mich gezwungen, tiefer in die Dokumentation einzusteigen, Architekturentscheidungen auf einem anderen Level zu durchdenken und mich mit Szenarien auseinanderzusetzen, die über alles hinausgehen, was ich bisher gebaut habe.

Die Prüfung liefert die Breite. Meine Projekte liefern die Tiefe. Beides zusammen ergibt ein Bild, das keines von beiden allein erzeugen könnte.

---

### Englisch: Feinste Nuancen

Die Prüfung ist auf Englisch. Die Sprache selbst war nicht das Thema -- sondern die Präzision der Formulierungen. AWS-Prüfungsfragen sind so konstruiert, dass der Unterschied zwischen zwei Antwortoptionen manchmal in einem einzigen Wort liegt.

Um das greifbar zu machen: "should" vs. "must", "minimize" vs. "eliminate", "cost-effective" vs. "cheapest". Das klingt zunächst trivial, aber hinter diesen Nuancen stecken unterschiedliche Architekturentscheidungen.

Wer "cost-effective" mit "cheapest" gleichsetzt, wählt die falsche Lösung. Wer "minimize" als "eliminate" liest, überdimensioniert die Architektur. In der Praxis sind die Szenarien deutlich komplexer -- aber das Prinzip bleibt: Jedes Wort zählt.

---

### Mehr als ein Zertifikat

Die AWS Solutions Architect Prüfung war kein Sammelpunkt im Lebenslauf. Sie war der Anspruch, Architektur-Entscheidungen auf einem Niveau zu treffen, das über meine eigenen Projekte hinausgeht.

Was ich aus der Vorbereitung mitnehme, geht über das Zertifikat hinaus. Ich habe gelernt, mich eigenständig in Themen einzuarbeiten, die weit über meinen praktischen Erfahrungshorizont hinausgehen -- und dabei ein Verständnis zu entwickeln, das nicht an einzelne Tools oder Services gebunden ist, sondern an die Fähigkeit, Probleme systematisch zu analysieren und die passende Architektur abzuleiten.

Die Zertifizierung ergänzt meine Projekte. Sie zeigt, dass das Wissen auch in der Breite vorhanden ist -- nicht nur dort, wo ich selbst gebaut habe.

---

### Bestanden: Februar 2026

Das eigentliche Learning war der Weg. Die Hunderten Fragen, die Fehleranalysen, die Kombination aus Theorie und Praxis und die ehrliche Auseinandersetzung mit den eigenen Grenzen.

Die Prüfung war ein Meilenstein. Die Denkweise war schon da. Jetzt habe ich die Werkzeuge, um sie in einer neuen Domäne umzusetzen.',
  'AWS Solutions Architect -- die Prüfung, die nicht fragt, was ein Service macht, sondern welche Lösung zu welchem Problem passt. Vorbereitet mit eigenem AWS-Account, echten Projekten und dem Anspruch, jedes Thema wirklich zu durchdringen. Warum die Denkweise nicht neu war -- und was die Prüfung trotzdem zu einer echten Herausforderung gemacht hat.',
  'published', false, 6, 1, 6,
  '2026-03-08T10:00:00Z'
);

-- Post 11: Diesen Blog auf AWS EKS deployen: Mein Abschlussprojekt
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Diesen Blog auf AWS EKS deployen: Mein Abschlussprojekt',
  'blog-aws-eks-abschlussprojekt',
  '### Ein Blog mit Zukunft

Am Ende der Weiterbildung steht ein Abschlussprojekt: eine produktionsreife, cloud-native Anwendung auf AWS. Vier Wochen Zeit, klare technische Anforderungen -- EKS, Terraform, CI/CD, Datenbank, Authentifizierung, ML-Service. Die Projektidee war freigestellt, solange die Rahmenbedingungen erfüllt sind.

Meine Entscheidung: diesen Tech-Blog. Nicht weil ein Blog die technisch anspruchsvollste Anwendung ist, sondern weil ich etwas bauen wollte, das über das Abschlussprojekt hinaus einen Zweck hat. Ein Showcase, den ich in Bewerbungen verlinken kann. Der den Fortschritt zeigt, den ich in den letzten Monaten gemacht habe -- und gleichzeitig alle technischen Anforderungen der Aufgabe abdeckt.

---

### Warum EKS

Es gab zwei Optionen: EKS oder Serverless mit Lambda. Für einen Blog wäre Serverless die kosteneffizientere Wahl gewesen. EKS ist für diese Anwendung überdimensioniert -- und genau das war der Punkt.

Kubernetes ist in der Praxis Standard für komplexe Webanwendungen. Unternehmen betreiben ihre Plattformen auf EKS, und wer dort arbeiten will, muss verstehen, wie Deployments, Services, Ingress und Pod-Scheduling zusammenspielen. Nicht nur theoretisch, sondern hands-on: Manifeste schreiben, Probleme debuggen und Konfigurationen iterieren.

Die Serverless-Architektur kannte ich bereits aus EcoKart. EKS war die Gelegenheit, die andere Seite kennenzulernen -- und bewusst die Variante zu wählen, die näher an Enterprise-Setups liegt.

---

### 9 Terraform-Module

Die Infrastruktur besteht aus neun Terraform-Modulen:

**Netzwerk und Security:** Eigene VPC mit Public und Private Subnets über zwei Availability Zones. Security Groups nach dem Prinzip der minimalen Rechte -- der ALB akzeptiert Traffic aus dem Internet, die EKS-Nodes nur vom ALB, die Datenbank nur von den Nodes. Kein direkter öffentlicher Zugriff auf irgendetwas außer dem Load Balancer.

**EKS-Cluster:** Managed Control Plane mit einer Node Group auf Spot Instances. Zwei Nodes im Betrieb, skalierbar zwischen eins und drei. Spot Instances sparen gegenüber On-Demand erheblich -- für ein Portfolio-Projekt ein akzeptabler Trade-off, weil kurzzeitige Unterbrechungen verschmerzbar sind.

**Datenbank:** RDS PostgreSQL in Private Subnets, verschlüsselt, automatische Backups, nicht aus dem Internet erreichbar. Für die Entwicklung pausierbar, um Kosten zu sparen.

**Frontend und Backend:** Das Frontend ist eine statische Anwendung auf Nginx, das Backend eine Express-API mit TypeScript. Beide laufen als Container in EKS, jeweils mit zwei Replicas, Health Probes und Resource Limits. Pod Anti-Affinity sorgt dafür, dass Replicas auf verschiedene Nodes verteilt werden.

**CDN und DNS:** CloudFront vor S3 für Blog-Assets, mit Origin Access Control -- kein öffentlicher S3-Zugriff. ACM-Zertifikat für HTTPS, Route 53 für DNS.

**Authentifizierung:** Cognito User Pool mit OAuth 2.0 für den Admin-Bereich. Optionale MFA, rollenbasierte Zugriffskontrolle.

**ML-Integration:** AWS Comprehend für automatische Sentiment-Analyse von Kommentaren -- die ML-Anforderung des Projekts, direkt in den Backend-Flow integriert.

---

### OIDC statt AWS-Keys

Die Projektvorgaben sahen AWS Access Keys als GitHub Secrets vor. Ich habe mich bewusst für OIDC-Federation entschieden -- den gleichen Ansatz wie bei EcoKart, aber diesmal von Anfang an eingeplant.

Das Prinzip: GitHub Actions fordert bei jedem Pipeline-Lauf ein kurzlebiges Token an. AWS validiert dieses Token gegen den registrierten OIDC-Provider und stellt temporäre Credentials aus, die nach einer Stunde automatisch ablaufen. Kein Schlüsselpaar, das rotiert werden muss. Kein Risiko, dass langlebige Credentials kompromittiert werden.

Das Ergebnis: Statt vier statischer Secrets braucht das gesamte Projekt nur zwei -- die OIDC-Rolle und das Datenbank-Passwort. Alles andere wird dynamisch aus dem Terraform State gelesen.

---

### Sechs Pipelines, ein Workflow

Die CI/CD-Architektur besteht aus sechs GitHub Actions Workflows.

Die **Deploy-Pipeline** durchläuft drei Stufen: Tests, Build, Deployment. Erst wenn alle 31 Tests bestehen, werden die Docker Images gebaut und in ECR gepusht. Erst wenn der Build erfolgreich ist, werden die Kubernetes-Manifeste angewendet. Die Pipeline wartet auf den Rollout und schlägt fehl, wenn Pods nicht starten -- kein stilles Ignorieren von Fehlern.

Die **Terraform-Pipeline** steuert die Infrastruktur: Validierung, Security Scans, Plan, Apply oder Destroy. Alles parameterisiert nach Waves und mit Concurrency-Kontrolle, damit nicht zwei Läufe gleichzeitig den State verändern.

Dazu eine **Security-Pipeline** mit drei parallelen Scans: Secrets-Erkennung, Terraform-Security-Checks und Policy-Validierung. Findings blockieren den Merge -- kein Durchwinken von bekannten Problemen.

---

### Wave-Strategie: Kosten kontrollieren

EKS kostet. Die Control Plane allein liegt bei rund 73 Dollar im Monat, dazu kommen Nodes, NAT Gateway und Datenbank. Für ein Portfolio-Projekt, das nicht dauerhaft laufen muss, ist das kein tragbares Modell.

Also habe ich die Infrastruktur in Waves aufgeteilt:

**Wave 1** enthält alles, was quasi nichts kostet: VPC, Security Groups, ECR, S3, Cognito, OIDC. Bleibt dauerhaft bestehen.

**Wave 2** fügt die Datenbank hinzu. Rund 13 Dollar im Monat, pausierbar wenn nicht gebraucht.

**Wave 3** ist der Full Stack: EKS, CloudFront, NAT Gateway. Das läuft nur, wenn ich aktiv entwickle oder den Blog demonstrieren möchte. Hochfahren, zeigen, herunterfahren.

Der Kern der Strategie: Alles ist vollständig reproduzierbar. Infrastruktur zerstören und in Minuten wieder aufbauen -- weil jede Konfiguration in Terraform liegt und die Deploy-Pipeline alle Werte dynamisch aus dem State liest. Kein manuelles Nachpflegen von Endpoints oder IDs nach einem Rebuild.

---

### Zwei Gleise: EKS für Showcase, Lightsail für Dauerbetrieb

EKS auf AWS war die bewusste Entscheidung für die Enterprise-Perspektive. Managed Control Plane, ALB Controller, IRSA für Service Accounts -- das ist das Setup, das in Unternehmen mit komplexen Anwendungen eingesetzt wird. Und genau deshalb bleibt EKS als Showcase-Infrastruktur im Repo: hochfahren, demonstrieren, herunterfahren.

Für den dauerhaften Betrieb des Blogs nutze ich eine Lightsail Instance. Gleicher Code, gleiche Container, aber auf einer einzelnen $5-Maschine statt einem Kubernetes-Cluster. Cognito und Comprehend laufen weiterhin als Managed Services -- die bleiben im AWS-Ökosystem. Nur die Hosting-Schicht wird bewusst vereinfacht.

Beide Varianten laufen aus dem gleichen Repository. Separate Terraform-Konfigurationen, separate Deploy-Workflows -- per Knopfdruck wählbar. EKS zeigt, dass ich Enterprise-Kubernetes verstehe. Lightsail zeigt, dass ich die richtige Lösung für den jeweiligen Anwendungsfall wählen kann. Und genau diese Abwägung -- nicht immer das Größte, sondern das Passende -- ist eine der wichtigsten Entscheidungen in der Cloud-Architektur.

---

### Reproduzierbar, nicht einmalig

Was mir an diesem Projekt am wichtigsten ist: Es ist kein einmaliger Aufbau. Alles -- vom Netzwerk bis zum letzten Pod -- liegt in Code. Terraform für die Infrastruktur, Kubernetes-Manifeste für die Anwendung, GitHub Actions für den Workflow.

Wenn morgen jemand sagt: „Zeig mir, wie du das aufgebaut hast“, kann ich die gesamte Infrastruktur in Minuten hochfahren, den Blog deployen und live demonstrieren. Und danach wieder zerstören, ohne dass etwas verloren geht. Das ist kein theoretisches Versprechen -- das ist der Workflow, den ich im Alltag nutze.

Neun Terraform-Module, zehn Kubernetes-Manifeste, sechs Pipelines, 31 Tests. Alles versioniert, alles reproduzierbar, alles transparent im öffentlichen Repository.

---

### Alles zusammen

Dieses Projekt bringt alles zusammen, was in den letzten Monaten entstanden ist. Terraform von EcoKart, Container-Erfahrung aus dem Homelab, CI/CD mit OIDC, Security-First-Denken aus dem Monitoring-Aufbau.

Kein isoliertes Lernprojekt, sondern die Zusammenführung von allem, was ich mir erarbeitet habe.

Und ein Blog, der seinen eigenen Aufbau dokumentiert. Angefangen bei der Frage, warum ich nach fast zwanzig Jahren im Vertrieb noch einmal bei null angefangen habe -- bis hierher, wo die Infrastruktur hinter diesem Text genauso Teil der Geschichte ist wie der Text selbst.',
  'Das Abschlussprojekt meiner Weiterbildung: Diesen Tech-Blog als Cloud-Native Anwendung auf AWS EKS bauen. Neun Terraform-Module, sechs CI/CD-Pipelines, OIDC statt AWS-Keys und eine Wave-Strategie, die Kosten kontrollierbar macht. Überdimensioniert für einen Blog -- aber genau darum ging es.',
  'published', true, 7, 1, 1,
  '2026-03-12T10:00:00Z'
);

-- Post-Tag links
INSERT INTO post_tags (post_id, tag_id) VALUES
  (1, 1),
  (1, 2),
  (1, 3),
  (1, 4),
  (2, 5),
  (2, 6),
  (2, 7),
  (2, 4),
  (2, 8),
  (3, 9),
  (3, 10),
  (3, 11),
  (3, 12),
  (3, 13),
  (4, 14),
  (4, 15),
  (4, 16),
  (4, 12),
  (4, 17),
  (5, 18),
  (5, 5),
  (5, 3),
  (5, 19),
  (5, 20),
  (6, 5),
  (6, 21),
  (6, 18),
  (6, 22),
  (6, 23),
  (7, 8),
  (7, 9),
  (7, 24),
  (7, 13),
  (7, 25),
  (7, 26),
  (8, 13),
  (8, 27),
  (8, 28),
  (8, 29),
  (8, 30),
  (9, 27),
  (9, 8),
  (9, 13),
  (9, 10),
  (10, 5),
  (10, 6),
  (10, 2),
  (10, 4),
  (11, 31),
  (11, 32),
  (11, 18),
  (11, 19),
  (11, 3);

COMMIT;
