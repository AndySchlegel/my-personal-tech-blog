-- =============================================================
-- Seed Data - 12 Blog Articles from the original blog
--
-- Populates the database with real content:
--   - 1 admin user
--   - 6 categories
--   - 12 published blog posts
--   - 25 tags linked to posts
--
-- Usage:
--   psql -d techblog -f seed.sql
--   OR: docker exec -i <db-container> psql -U bloguser -d techblog < seed.sql
-- =============================================================

-- Start a transaction so everything succeeds or nothing does
BEGIN;

-- ----- CLEAN UP (safe to re-run) -----
-- Delete in reverse dependency order
DELETE FROM post_tags;
DELETE FROM comments;
DELETE FROM posts;
DELETE FROM tags;
DELETE FROM categories;
DELETE FROM users;

-- Reset auto-increment counters so IDs start from 1
ALTER SEQUENCE users_id_seq RESTART WITH 1;
ALTER SEQUENCE categories_id_seq RESTART WITH 1;
ALTER SEQUENCE posts_id_seq RESTART WITH 1;
ALTER SEQUENCE tags_id_seq RESTART WITH 1;
ALTER SEQUENCE comments_id_seq RESTART WITH 1;

-- ----- USER -----
-- Cognito ID is a placeholder until real Cognito is set up
INSERT INTO users (cognito_id, email, display_name, role)
VALUES ('seed-admin-placeholder', 'andy@schlegel.dev', 'Andy Schlegel', 'admin');

-- ----- CATEGORIES -----
INSERT INTO categories (name, slug, description) VALUES
  ('AWS & Cloud',           'aws-cloud',      'AWS Certifications, Cloud Architecture and Best Practices'),
  ('DevOps & CI/CD',        'devops',          'CI/CD, Docker, Kubernetes and Infrastructure as Code'),
  ('Homelab & Self-Hosting', 'homelab',         'NAS Setup, Self-Hosted Services and Homelab Projects'),
  ('Networking & Security',  'networking',      'VPN, Reverse Proxy, DNS and Security Best Practices'),
  ('Tools & Productivity',   'tools',           'Development Tools, Terminal Setup and Workflow Automation'),
  ('Certifications',         'certifications',  'Certifications, Study Plans and Exam Tips');

-- ----- TAGS -----
INSERT INTO tags (name, slug, source) VALUES
  ('Synology',      'synology',      'manual'),
  ('NAS',           'nas',           'manual'),
  ('Docker',        'docker',        'manual'),
  ('Homelab',       'homelab',       'manual'),
  ('DevOps',        'devops',        'manual'),
  ('AWS',           'aws',           'manual'),
  ('Certification', 'certification', 'manual'),
  ('Cloud',         'cloud',         'manual'),
  ('Learning',      'learning',      'manual'),
  ('Tailscale',     'tailscale',     'manual'),
  ('Traefik',       'traefik',       'manual'),
  ('VPN',           'vpn',           'manual'),
  ('Networking',    'networking',    'manual'),
  ('n8n',           'n8n',           'manual'),
  ('Automation',    'automation',    'manual'),
  ('Hetzner',       'hetzner',       'manual'),
  ('Self-Hosting',  'self-hosting',  'manual'),
  ('Monitoring',    'monitoring',    'manual'),
  ('Dashboard',     'dashboard',     'manual'),
  ('GitHub',        'github',        'manual'),
  ('Git',           'git',           'manual'),
  ('Terminal',      'terminal',      'manual'),
  ('Productivity',  'productivity',  'manual'),
  ('DNS',           'dns',           'manual'),
  ('Nginx',         'nginx',         'manual'),
  ('Linux',         'linux',         'manual'),
  ('Best Practices','best-practices','manual'),
  ('Production',    'production',    'manual');

-- ----- POSTS -----
-- All 12 articles from the original blog, published with staggered dates

-- Post 1: Synology DS925+ Setup Guide (featured)
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Synology DS925+ als DevOps Homelab: Der komplette Setup-Guide',
  'synology-ds925-devops-homelab-setup',
  'Die Synology DS925+ ist die perfekte Platform für DevOps Engineers. Mit AMD Ryzen V1500B (4 Cores), bis zu 32GB RAM und nativer Docker-Unterstützung bietet sie genug Power für produktive Workloads.

## Setup in 5 Schritten

1. **Initial Setup**: Synology Assistant findet NAS automatisch, DSM 7.2 Installation dauert ca. 15 Min
2. **Storage Pool**: RAID 5 für Balance zwischen Performance und Redundanz
3. **Container Manager**: Docker aus Package Center installieren
4. **SSH aktivieren**: Für Automation und Deployment
5. **Erste Projekte**: Blog-App, Dashy, n8n deployen

Der Container Manager macht Docker-Deployment super einfach. Alternativ bietet Portainer mehr Features für fortgeschrittene Setups.',
  'Vom Unboxing bis zum ersten Docker-Container: Wie ich meine Synology DS925+ als zentrale Homelab-Platform eingerichtet habe.',
  'published', true, 8, 1, 3,
  '2026-01-10T10:00:00Z'
);

-- Post 2: AWS Cloud Practitioner (featured)
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'AWS Cloud Practitioner: Von Null zur Zertifizierung in 6 Wochen',
  'aws-cloud-practitioner-guide',
  'Die AWS Cloud Practitioner (CLF-C02) ist der perfekte Einstieg in AWS. Nach 6 Wochen Vorbereitung habe ich mit 850/1000 Punkten bestanden.

## Mein Lernplan

**Woche 1-2**: AWS Skill Builder Exam Prep (kostenlos) + "Overview of AWS" Whitepaper
**Woche 3-4**: Udemy Kurs von Stephane Maarek + Hands-on im Free Tier
**Woche 5**: Tutorials Dojo Practice Tests (6 Sets)
**Woche 6**: Final Review aller Notizen

## Die 4 Exam-Domains

1. Cloud Concepts (24%) - Shared Responsibility Model, 6 R''s of Migration
2. Security & Compliance (30%) - IAM, GuardDuty, Shield, WAF
3. Technology & Services (34%) - EC2, S3, RDS, Lambda, VPC
4. Billing & Pricing (12%) - Support Plans, Cost Explorer

**Pro-Tipp**: Practice Exams sind Gold wert! Mindestens 3-4 vollständige Tests machen.',
  'Mein kompletter Lernplan, Best Practices und Exam-Tipps für die AWS Cloud Practitioner Zertifizierung.',
  'published', true, 12, 1, 6,
  '2026-01-15T10:00:00Z'
);

-- Post 3: Tailscale + Traefik (featured)
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Tailscale VPN + Traefik: Sichere Homelab-Cloud Verbindung',
  'tailscale-traefik-setup',
  'Mit Tailscale VPN und Traefik Reverse Proxy verbinde ich meine Synology NAS sicher mit einem Hetzner Cloud Server - ohne Port Forwarding am Router.

## Die Architektur

Internet -> Cloudflare DNS -> Hetzner VPS (Public IP) -> Traefik -> Tailscale VPN -> Synology NAS (privat)

## Vorteile

- Keine offenen Ports am Router
- End-to-End Encryption via Tailscale
- Automatische SSL-Zertifikate (Let''s Encrypt)
- NAT Traversal - funktioniert auch hinter Firewall

## Setup in 6 Schritten

1. Tailscale auf Hetzner & Synology installieren
2. Traefik Docker Container auf Hetzner
3. Services auf NAS für Tailscale exposen
4. Traefik Labels für Routing konfigurieren
5. DNS A-Record auf Hetzner IP setzen
6. Let''s Encrypt HTTPS aktivieren

**Kosten**: ~4 EUR/Monat für unbegrenzte Services!',
  'Kein Port Forwarding, keine öffentliche IP - trotzdem sicher auf alle Services zugreifen.',
  'published', true, 15, 1, 4,
  '2026-01-20T10:00:00Z'
);

-- Post 4: n8n Self-Hosting
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'n8n Self-Hosting auf Hetzner: Workflow-Automation für unter 5 EUR/Monat',
  'n8n-hetzner-selfhosting',
  'n8n ist eine mächtige Open-Source Alternative zu Zapier. Self-Hosted auf Hetzner kostet es nur ~3,79 EUR/Monat statt 20 EUR+ bei Cloud-Anbietern.

## Warum Self-Hosting?

- Unbegrenzte Workflows
- Volle Datenkontrolle
- Custom Nodes möglich
- 10x günstiger als Cloud

## Deployment-Stack

- **Server**: Hetzner CAX11 (4GB RAM, 2 vCPU)
- **OS**: Ubuntu 22.04
- **Container**: Docker + Docker Compose
- **Reverse Proxy**: Traefik für HTTPS
- **Database**: PostgreSQL (optional, für Production)

## docker-compose.yml Setup

```yaml
version: ''3.8''
services:
  n8n:
    image: n8nio/n8n:latest
    restart: always
    environment:
      - N8N_HOST=n8n.yourdomain.com
      - WEBHOOK_URL=https://n8n.yourdomain.com/
      - GENERIC_TIMEZONE=Europe/Berlin
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(`n8n.yourdomain.com`)"
      - "traefik.http.routers.n8n.tls.certresolver=letsencrypt"
```

Nach 10 Minuten Setup läuft n8n produktiv mit HTTPS!',
  'Wie ich n8n auf einem Hetzner Cloud Server deployed habe - mit Docker, Traefik und automatischem SSL.',
  'published', false, 10, 1, 5,
  '2026-01-25T10:00:00Z'
);

-- Post 5: Dashy Dashboard
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Dashy Homelab Dashboard: Alle Services auf einen Blick',
  'dashy-homelab-dashboard',
  'Dashy ist das perfekte Dashboard für dein Homelab. Selbst-gehostet, Open-Source, und unglaublich customizable.

## Features

- Status-Checks für alle Services
- Themes & Icon-Packs
- Sections & Categories
- Drag & Drop UI Editor
- Auth & Multi-User Support

## Docker Setup

```bash
docker run -d \
  -p 4000:80 \
  -v ./dashy-conf.yml:/app/user-data/conf.yml \
  --name dashy \
  --restart=always \
  lissy93/dashy:latest
```

## Meine Config-Struktur

```yaml
sections:
  - name: "Homelab Services"
    items:
      - title: "Blog App"
        url: "https://blog.example.com"
        statusCheck: true
      - title: "n8n Automation"
        url: "https://n8n.example.com"
        statusCheck: true
```

**Deployment-Zeit**: Unter 5 Minuten für ein professionelles Dashboard!',
  'Mit Dashy alle Self-Hosted Services übersichtlich organisieren - inklusive Status-Checks und modernem Design.',
  'published', false, 6, 1, 3,
  '2026-01-28T10:00:00Z'
);

-- Post 6: GitHub Foundations
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'GitHub Foundations Certification: Der komplette Study Guide',
  'github-foundations-certification',
  'Die GitHub Foundations Certification validiert dein Grundwissen über Git, GitHub, und Collaboration-Workflows.

## Exam Details

- **Dauer**: 120 Minuten
- **Fragen**: 75 (60 scored + 15 pretest)
- **Format**: Multiple Choice
- **Kosten**: Kostenlos für Studenten!
- **Sprachen**: EN, PT, ES, KR, JP

## Hauptthemen

### 1. Git Basics
- Repositories, Commits, Branches
- Merge vs. Rebase
- Git Workflow Best Practices

### 2. GitHub Collaboration
- Pull Requests & Code Reviews
- Issues & Project Boards
- GitHub Actions Basics

### 3. GitHub Products
- GitHub Free vs. Pro vs. Teams
- GitHub Pages
- GitHub Packages

### 4. Security & Administration
- Branch Protection Rules
- Dependabot
- Code Scanning

## Study Resources

1. **Official**: Microsoft Learn Path (kostenlos)
2. **Practice**: GitHub Skills Labs
3. **Community**: Study Guides auf GitHub

**Pro-Tipp**: Hands-on Erfahrung ist wichtiger als nur Theorie - erstelle eigene Repos und nutze alle Features!',
  'Alles was du für die GitHub Foundations Zertifizierung wissen musst - kostenlos für Studenten!',
  'published', false, 9, 1, 6,
  '2026-02-01T10:00:00Z'
);

-- Post 7: iTerm2 + Starship Terminal
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'iTerm2 + Starship: Das ultimative Terminal-Setup für Mac',
  'iterm2-starship-setup',
  'Ein gut konfiguriertes Terminal macht den Unterschied zwischen Frust und Flow. Hier ist mein Setup.

## Der Stack

- **iTerm2**: Terminal-Emulator mit Split Panes & Tabs
- **Zsh**: Moderne Shell (macOS default)
- **Oh-My-Zsh**: Plugin-Framework
- **Starship**: Cross-Shell Prompt
- **Nerd Fonts**: Icons & Glyphs

## Installation

```bash
# 1. iTerm2 installieren
brew install --cask iterm2

# 2. Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 3. Starship
brew install starship
echo ''eval "$(starship init zsh)"'' >> ~/.zshrc

# 4. Nerd Font
brew tap homebrew/cask-fonts
brew install --cask font-fira-code-nerd-font
```

## Meine Plugins

```bash
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  docker
  kubectl
)
```

## Starship Config

```toml
# ~/.config/starship.toml
[character]
success_symbol = "[->](bold green)"
error_symbol = "[->](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = true
```

**Warum Starship statt Powerlevel10k?** Powerlevel10k ist on Life Support - Starship ist aktiv maintained und schneller!',
  'Von langweiligem Terminal zu produktivem Workspace - mit iTerm2, Oh-My-Zsh, und Starship.',
  'published', false, 7, 1, 5,
  '2026-02-03T10:00:00Z'
);

-- Post 8: Domain Setup
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Domain Setup: Ionos vs. Infomaniak - Was ich gelernt habe',
  'domain-setup-ionos-infomaniak',
  'Für meine Self-Hosting Projekte nutze ich Domains von Ionos und Infomaniak. Hier ist mein Vergleich.

## Ionos

**Vorteile:**
- Günstige .de Domains (~1 EUR erstes Jahr)
- Deutsche Firma, deutscher Support
- Einfaches Control Panel
- Inkl. E-Mail Postfach

**Nachteile:**
- DNS Propagation manchmal langsam
- Renewal-Preise höher
- Upselling im Dashboard

## Infomaniak

**Vorteile:**
- Schweizer Datenschutz
- Ökostrom-powered
- Sehr gute API
- Transparente Preise
- Gratis WHOIS Privacy

**Nachteile:**
- Etwas teurer als Ionos
- Weniger bekannt in Deutschland

## DNS Konfiguration

Beide bieten Standard DNS Records:

```
A Record: Domain -> IP
CNAME: Subdomain -> Domain
MX: Mail Server
TXT: Verification (SPF, DKIM)
```

### Typische Setup-Zeit
- **Ionos**: DNS Änderungen ~1-2 Stunden
- **Infomaniak**: DNS Änderungen ~30-60 Min

## Meine Empfehlung

**Ionos**: Für .de Domains, wenn Budget wichtig ist
**Infomaniak**: Für internationale Domains, wenn Datenschutz Priorität hat

Beide funktionieren einwandfrei mit Cloudflare als DNS-Provider!',
  'Eigene Domains registrieren und konfigurieren - mit Ionos und Infomaniak im Vergleich.',
  'published', false, 5, 1, 4,
  '2026-02-05T10:00:00Z'
);

-- Post 9: AWS SAA Lernplan
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'AWS Solutions Architect Associate: Mein Lernplan',
  'aws-solutions-architect-learning-path',
  'Nach dem Cloud Practitioner ist der AWS Solutions Architect Associate der nächste logische Schritt.

## Unterschied zu Cloud Practitioner

**Cloud Practitioner**: Was ist AWS?
**Solutions Architect**: Wie designed man auf AWS?

## Voraussetzungen

- 1+ Jahre AWS Erfahrung (empfohlen)
- Cloud Practitioner hilfreich, aber nicht Pflicht
- Grundkenntnis in Networking

## Exam Details

- **Dauer**: 130 Minuten
- **Fragen**: 65
- **Passing Score**: 720/1000
- **Kosten**: $150 USD

## Mein 3-Monats-Plan

### Monat 1: Fundamentals
- **Woche 1-2**: VPC Deep Dive (Subnets, Route Tables, NAT, IGW)
- **Woche 3**: EC2 Advanced (Instance Types, Pricing, Auto Scaling)
- **Woche 4**: S3 & Storage Services

### Monat 2: Advanced Services
- **Woche 5**: Databases (RDS, DynamoDB, Aurora, ElastiCache)
- **Woche 6**: Application Services (ELB, CloudFront, Route 53)
- **Woche 7**: Security & Identity (IAM Advanced, KMS, Secrets Manager)
- **Woche 8**: Monitoring (CloudWatch, CloudTrail, Config)

### Monat 3: Practice & Review
- **Woche 9-10**: Tutorials Dojo Practice Exams (6 Sets)
- **Woche 11**: Weak Areas Review
- **Woche 12**: Final Exam Simulation

## Top Learning Resources

1. **Adrian Cantrill**: Deep-dive Course (sehr technisch)
2. **Stephane Maarek**: Udemy Course (gut strukturiert)
3. **AWS Well-Architected Framework**: Pflichtlektüre!
4. **AWS re:Invent Videos**: Für spezifische Services',
  'Von Cloud Practitioner zu Solutions Architect - wie ich die SAA-C03 Prüfung vorbereite.',
  'published', false, 10, 1, 6,
  '2026-02-08T10:00:00Z'
);

-- Post 10: Docker Compose Best Practices
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Docker Compose Best Practices für Production',
  'docker-compose-production-best-practices',
  'Docker Compose ist perfekt für Development, aber Production braucht Extra-Konfiguration.

## Development vs. Production

### Development
```yaml
version: ''3.8''
services:
  app:
    build: .
    volumes:
      - .:/app  # Live-Reload
    ports:
      - "3000:3000"
```

### Production
```yaml
version: ''3.8''
services:
  app:
    image: myapp:1.2.3  # Tagged image
    restart: unless-stopped
    env_file: .env.production
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Meine Best Practices

### 1. Resource Limits
```yaml
deploy:
  resources:
    limits:
      cpus: ''0.50''
      memory: 512M
    reservations:
      memory: 256M
```

### 2. Health Checks
Verhindert Traffic zu unhealthy Containern.

### 3. Restart Policies
- **no**: Nie neu starten
- **always**: Immer (auch nach System-Reboot)
- **unless-stopped**: Ausser manuell gestoppt
- **on-failure**: Nur bei Error

### 4. Secrets Management
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt
services:
  app:
    secrets:
      - db_password
```

### 5. Networks
Isoliere Services in eigene Networks.

### 6. Logging
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

**Pro-Tipp**: Nutze `docker-compose.override.yml` für local Development Overrides!',
  'Von Development zu Production - wie ich Docker Compose Setups production-ready mache.',
  'published', false, 8, 1, 2,
  '2026-02-10T10:00:00Z'
);

-- Post 11: Linux Essentials
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Linux Essentials Certification: Was bringt es wirklich?',
  'linux-essentials-certification-review',
  'Die Linux Essentials Zertifizierung von LPI ist ein guter Einstieg in Linux - aber ist sie das Geld wert?

## Was wird getestet?

### 1. Linux Community & Open Source
- FOSS Konzepte
- Linux Distributions
- Major Open Source Applications

### 2. Navigation im System
- Command Line Basics
- File System Hierarchy
- Archive & Compression

### 3. Power der Command Line
- Text Processing
- Shell Scripting Basics
- Process Management

### 4. Security & Permissions
- User & Group Management
- File Permissions
- Basic Security Concepts

## Meine Erfahrung

**Vorteile:**
- Gute Foundation für weitere LPI Certs
- Vendor-neutral (nicht nur Ubuntu/Red Hat)
- Praxis-orientiert

**Nachteile:**
- Relativ teuer (~120 EUR)
- Weniger bekannt als Red Hat/CompTIA
- Online-Proctoring manchmal problematisch

## Ist es das wert?

**Ja, wenn:**
- Du kompletter Linux-Neuling bist
- Du Richtung LPIC-1/LPIC-2 willst
- Du strukturiertes Lernen bevorzugst

**Nein, wenn:**
- Du bereits täglich mit Linux arbeitest
- Budget knapp ist (Free Resources wie Linux Journey nutzen)
- Arbeitgeber Linux Certs nicht wertschätzt

## Alternative Learning Paths

1. **Free**: Linux Journey, OverTheWire (Bandit)
2. **Günstig**: Udemy Linux Kurse (~15 EUR)
3. **Offiziell**: Red Hat Learning Subscription

**Mein Tipp**: Lern Linux hands-on mit eigenem Server/NAS - praktische Erfahrung ist mehr wert als ein Zertifikat!',
  'Meine Erfahrung mit der LPI Linux Essentials Zertifizierung - und ob sie sich lohnt.',
  'published', false, 6, 1, 6,
  '2026-02-13T10:00:00Z'
);

-- Post 12: Traefik vs Nginx
INSERT INTO posts (title, slug, content, excerpt, status, featured, reading_time_minutes, author_id, category_id, published_at)
VALUES (
  'Traefik vs. Nginx: Welcher Reverse Proxy für Homelab?',
  'traefik-vs-nginx-comparison',
  'Beide sind exzellent - aber sie haben unterschiedliche Stärken.

## Nginx Reverse Proxy

**Vorteile:**
- Battle-tested, extrem stabil
- Sehr performant (C-basiert)
- Riesige Community
- Viele Tutorials & Beispiele

**Nachteile:**
- Config-Files manuell schreiben
- SSL-Renewals manuell (oder certbot)
- Jede Änderung = nginx reload

### Typische Nginx Config
```nginx
server {
    listen 80;
    server_name blog.example.com;

    location / {
        proxy_pass http://192.168.1.10:3000;
        proxy_set_header Host $host;
    }
}
```

## Traefik

**Vorteile:**
- Auto-Discovery (Docker Labels)
- Automatisches SSL (Let''s Encrypt)
- Schönes Dashboard
- Kein Config-Reload nötig

**Nachteile:**
- Steile Lernkurve am Anfang
- Komplexere Debugging
- Etwas mehr Resource-Hungry

### Typische Traefik Config
```yaml
# docker-compose.yml
services:
  app:
    image: myapp
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`blog.example.com`)"
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"
```

## Meine Empfehlung

**Nginx wenn:**
- Du statische Configs bevorzugst
- Performance kritisch ist
- Du nginx bereits kennst

**Traefik wenn:**
- Du viele Docker-Services hast
- Auto-SSL wichtig ist
- Services häufig wechseln

**Mein Setup**: Traefik für Homelab (wegen Auto-SSL), nginx für statische Sites.',
  'Der grosse Vergleich: Traefik oder Nginx als Reverse Proxy für Self-Hosting Projekte.',
  'published', false, 7, 1, 2,
  '2026-02-15T10:00:00Z'
);

-- ----- POST-TAG LINKS -----
-- Connect each post to its tags using the IDs from above

-- Post 1 (Synology): synology, nas, docker, homelab, devops
INSERT INTO post_tags (post_id, tag_id) VALUES
  (1, 1), (1, 2), (1, 3), (1, 4), (1, 5);

-- Post 2 (AWS CCP): aws, certification, cloud, learning
INSERT INTO post_tags (post_id, tag_id) VALUES
  (2, 6), (2, 7), (2, 8), (2, 9);

-- Post 3 (Tailscale): tailscale, traefik, vpn, networking, homelab
INSERT INTO post_tags (post_id, tag_id) VALUES
  (3, 10), (3, 11), (3, 12), (3, 13), (3, 4);

-- Post 4 (n8n): n8n, automation, hetzner, self-hosting, docker
INSERT INTO post_tags (post_id, tag_id) VALUES
  (4, 14), (4, 15), (4, 16), (4, 17), (4, 3);

-- Post 5 (Dashy): dashboard, homelab, docker, monitoring
INSERT INTO post_tags (post_id, tag_id) VALUES
  (5, 19), (5, 4), (5, 3), (5, 18);

-- Post 6 (GitHub Foundations): github, certification, git, learning, devops
INSERT INTO post_tags (post_id, tag_id) VALUES
  (6, 20), (6, 7), (6, 21), (6, 9), (6, 5);

-- Post 7 (iTerm2): terminal, productivity
INSERT INTO post_tags (post_id, tag_id) VALUES
  (7, 22), (7, 23);

-- Post 8 (Domains): dns, networking
INSERT INTO post_tags (post_id, tag_id) VALUES
  (8, 24), (8, 13);

-- Post 9 (AWS SAA): aws, certification, cloud, learning
INSERT INTO post_tags (post_id, tag_id) VALUES
  (9, 6), (9, 7), (9, 8), (9, 9);

-- Post 10 (Docker Compose): docker, devops, production, best-practices
INSERT INTO post_tags (post_id, tag_id) VALUES
  (10, 3), (10, 5), (10, 28), (10, 27);

-- Post 11 (Linux Essentials): linux, certification, learning
INSERT INTO post_tags (post_id, tag_id) VALUES
  (11, 26), (11, 7), (11, 9);

-- Post 12 (Traefik vs Nginx): traefik, nginx, homelab, docker
INSERT INTO post_tags (post_id, tag_id) VALUES
  (12, 11), (12, 25), (12, 4), (12, 3);

-- Done!
COMMIT;
