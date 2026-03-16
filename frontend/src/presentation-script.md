# Presentation Script -- Abschlussprojekt Andy Schlegel

## Gesamtzeit: ~20-25 Minuten (+ Diskussion)

---

## Tab 1: Projekt (2-3 Min)

**Einstieg:**
"Das hier ist mein Abschlussprojekt -- ein Tech-Blog, der gleichzeitig als vollstaendige Cloud-Native Plattform auf AWS laeuft. Nicht einfach eine App deployen, sondern eine Infrastruktur aufbauen, die wie ein reales System betrieben werden kann."

**Kernpunkte:**
- 9 Terraform Module, 8 Workflows, 31 Tests, 42 Lessons Learned
- Dual-Track Hosting: EKS fuer Showcase (~143 Euro/Sprint), Lightsail fuer Dauerbetrieb (~5.50 Euro)
- 3 AWS ML-Services integriert (Comprehend, Translate, Polly)
- 100% reproduzierbar -- Provision, Deploy, Destroy, Repeat

**Ueberleitung:** "Schauen wir uns an wie das technisch aufgebaut ist."

---

## Tab 2: Architektur (2 Min)

**Kernpunkte:**
- Region eu-central-1 Frankfurt, 2 Availability Zones
- Traffic Flow: User -> Route 53 -> ALB mit HTTPS -> VPC -> EKS Pods
- Private Subnets fuer EKS Nodes und RDS -- nichts direkt erreichbar
- ML-Services (Comprehend, Translate, Polly) ueber NAT Gateway angebunden
- S3 + CloudFront fuer statische Assets

**Keep it simple:** "Das Diagramm zeigt den kompletten Weg vom User bis zur Datenbank. Alles was sensibel ist, liegt in Private Subnets."

---

## Tab 3: Terraform (2 Min)

**Kernpunkte:**
- 9 Module, alle von Grund auf selbst geschrieben -- keine fertigen Community-Module
- Wave-basiertes Deployment: Wave 0 (OIDC) -> Wave 1 (Netzwerk, ECR, Cognito) -> Wave 2 (RDS) -> Wave 3 (EKS)
- Highlight: OIDC-Modul ueberlebt den Destroy-Zyklus -- keine manuellen Secret-Updates noetig
- NAT Gateway optional zuschaltbar (Kosten sparen wenn nicht gebraucht)

**Ueberleitung:** "Die Module werden nicht manuell deployed, sondern ueber Pipelines."

---

## Tab 4: CI/CD (2 Min)

**Kernpunkte:**
- 6 Core-Pipelines + 2 Status-Monitore, alles mit OIDC -- keine AWS Keys im CI/CD
- deploy.yml liest alle Infra-Werte dynamisch aus dem Terraform State
- Nach einem Destroy + Apply brauche ich nur 2 Secrets: die OIDC Role ARN und das DB-Passwort
- Security-Scan laeuft automatisch bei jedem Push/PR

**Key Takeaway:** "Das Ziel war: nach einem kompletten Teardown kann ich die Infrastruktur in unter 30 Minuten wieder hochfahren, ohne irgendwas manuell anfassen zu muessen."

---

## Tab 5: Security (1-2 Min)

**Kernpunkte:**
- 3 Tools: Trufflehog (Secrets), tfsec (Terraform), Checkov (AWS Best Practices)
- Checkov: 142 passed, 42 triaged -- jeder einzelne Finding explizit bewertet
- 3 davon gefixt, 39 bewusst suppressed mit Begruendung (z.B. kein Multi-AZ RDS weil Dev-Umgebung)
- 0 deferred -- nichts ignoriert

**Key Takeaway:** "Security nicht als Checkbox, sondern jeder einzelne Finding dokumentiert und begruendet."

---

## Tab 6: Kubernetes (2-3 Min)

**Script:**
"12 Manifest-Dateien, nummeriert von 00 bis 11 -- die Nummer zeigt die Reihenfolge in der sie angewendet werden."

**Einfach erklaert:**
- **Namespace** = eigener Bereich im Cluster, damit Blog-Sachen isoliert sind
- **ConfigMap + Secrets** = Konfiguration und Passwoerter, getrennt vom Code
- **Deployment** = sagt Kubernetes: "Starte je 2 Backend- und 2 Frontend-Pods." Der HPA uebernimmt danach die Kontrolle und skaliert bei niedrigem Traffic auf je 1 Pod runter -- deshalb sieht man im Normalbetrieb nur 1+1
- **Service** = interne Adresse damit sich Pods gegenseitig finden koennen
- **Ingress** = der Eingang von aussen -- verbindet den ALB Load Balancer mit den Pods
- **HPA** = Horizontal Pod Autoscaler -- uebernimmt nach dem Start die Replica-Steuerung. Skaliert bei niedrigem Traffic auf das Minimum (je 1 Pod) und bei hoher CPU (ueber 70%) auf bis zu 4 Backend- bzw. 3 Frontend-Pods
- **IRSA** = jeder Pod bekommt nur die AWS-Rechte die er braucht, nicht die vom ganzen Server
- **DB Init Job** = einmaliger Task der die Datenbank-Tabellen und Blog-Posts anlegt

**Key Takeaway:** "Die Manifeste sind so gebaut, dass die Pipeline sie mit echten Werten fuellen kann -- nichts ist hardcoded."

---

## Tab 7: ML Services (2 Min)

**Kernpunkte:**
- **Comprehend**: Analysiert Blog-Posts automatisch und schlaegt Tags vor. Analysiert Kommentar-Stimmung -- negativ ueber 70% wird automatisch geflaggt
- **Translate**: Alle Posts on-demand auf Englisch uebersetzt, Ergebnis in PostgreSQL gecacht
- **Polly**: Liest Blog-Posts vor, Audio in S3 gecacht, Speed-Controls 0.5x-2x

**Kosten:** ~2.21 Euro pro Deploy-Zyklus fuer alle 3 Services zusammen

**Ueberleitung:** "Das zeige ich gleich alles live."

---

## Tab 8: Lessons Learned (1-2 Min)

**Script:**
"42 Lessons Learned insgesamt -- hier die Highlights."

**Top 3 zum Ansprechen:**
1. **IRSA statt Node IAM (#8):** "Die wichtigste Erkenntnis -- EKS blockiert den direkten Zugriff auf AWS Services vom Pod aus. Ohne Pod-Level IAM geht gar nichts."
2. **EKS Cluster Security Group (#14):** "EKS erstellt eine eigene Security Group die man nicht selbst anlegt. Meine eigenen SG-Regeln haben ins Leere gegriffen bis ich das verstanden habe."
3. **Full Lifecycle Verified (#30):** "Reproduzierbarkeit beweist man nicht durch einen Plan, sondern durch den vollen Zyklus. Jede Iteration hat neue Edge Cases aufgedeckt."

**Kurz erwaehnen:**
- Separate ACM-Certs (#24): Globale vs. regionale Services brauchen getrennte Zertifikate
- ALB Controller Orphans (#26): K8s erstellt Ressourcen ausserhalb von Terraform -- Cleanup-Reihenfolge ist entscheidend
- Comprehend Deutsche Ironie (#35): "Ganz schoen ueberzogen dargestellt" wird als POSITIVE erkannt -- manuelle Moderation bleibt Pflicht

---

## Tab 9: EKS vs. Serverless (1 Min)

**Script:**
"Warum EKS und nicht Lambda? Weil ich Container-Orchestrierung lernen wollte -- Deployments, Services, Ingress, HPA, IRSA. Das sind Skills die in groesseren Teams und komplexen Anwendungen Standard sind. Serverless waere einfacher und billiger gewesen, aber der Lerneffekt waere deutlich kleiner."

---

## Tab 10: Monitoring (1-2 Min)

**Script:**
"Prometheus + Grafana, self-hosted via Helm. Drei Dashboards: Cluster-Gesundheit, HPA Auto-Scaling und AWS ML Services. Kostet null extra weil es auf den gleichen Spot Nodes laeuft."

**Ueberleitung:** "Das zeige ich jetzt live im Stresstest."

---

## Tab 11: Live Demo (5-7 Min)

### Schritt 1: Cluster-Ueberblick (30s)
```bash
kubectl get pods -n blog
```
- Alle Pods Running, 0 Restarts zeigen
- Im Normalbetrieb je 1 Pod (HPA hat runterskaliert) -- das ist korrekt, nicht ein Fehler

### Schritt 2: Blog im Browser (1 Min)
- Seite oeffnen, durch einen Post klicken
- **Translate**: Sprache umschalten DE/EN -- Post wird uebersetzt
- **Polly**: Play-Button, Audio abspielen, Speed aendern

### Schritt 3: Comprehend + Telegram (2 Min)
- Positiven Kommentar schreiben -- Tags werden automatisch vorgeschlagen
- Negativen Kommentar schreiben -- Sentiment-Badge zeigt NEGATIVE, wird auto-geflaggt
- **Telegram**: Handy zeigen -- Notification kommt sofort rein

### Schritt 4: Stresstest + Grafana (2-3 Min)
```bash
# Aktuelle HPA-Werte zeigen
kubectl get hpa -n blog

# Stresstest starten
kubectl run stress --image=busybox --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://backend.blog.svc.cluster.local:3000/api/posts; done"
```
- Grafana Dashboard oeffnen -- CPU steigt, HPA skaliert hoch
- Warten bis Backend von 1 auf 3-4 Pods hochskaliert (~60s)
```bash
# Ergebnis zeigen
kubectl get hpa -n blog

# Aufraumen
kubectl delete pod stress
```
- Zeigen wie Replicas wieder runterskalieren

### Schritt 5: Grafana ML Dashboard (30s)
- Translate/Polly API Calls zeigen die durch die Demo entstanden sind

---

## Tab 12: Ausblick (1 Min)

**Script:**
"Was bewusst nicht implementiert wurde und warum: Redis waere Overkill fuer 12 Posts, Multi-AZ RDS ist Produktions-Pflicht aber hier Dev-Umgebung, WAF bringt ohne echten Traffic keinen Demo-Mehrwert. Das sind keine offenen Punkte, sondern bewusste Entscheidungen."

---
---

# Hintergrundwissen -- Einfache Erklaerungen

Die folgenden Erklaerungen sind Hintergrundwissen fuer dich, damit du bei
Rueckfragen in der Praesentation sicher antworten kannst.

---

## EKS Security Groups -- warum die eigene SG nicht greift

Wenn du einen EKS-Cluster erstellst, erstellt AWS automatisch eine
**Cluster Security Group**. Die haengst du nicht selbst an -- AWS macht das.
Diese Cluster-SG wird an die Control Plane ENIs UND an alle Managed Nodes
angehaengt.

Du hast in Terraform eine eigene Node-SG erstellt mit Regeln wie "erlaube
Traffic von ALB zu den Nodes". Aber die Pods kommunizieren ueber die
**Cluster-SG**, nicht ueber deine Custom-SG. Deine Regel greift ins Leere.

**Die Loesung:** Die Ingress-Regel (ALB -> Pods) muss auf die
**EKS Cluster Security Group** gesetzt werden:
```
aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
```

**Beim ALB das gleiche Spiel:** Der ALB Controller erstellt Target Groups
mit Pod-IPs (target-type: ip). Der Traffic geht ALB -> Pod-IP -> Cluster-SG.
Wenn die Cluster-SG den ALB nicht kennt, kommen die Requests nicht durch.

**Einfach gesagt:** "EKS hat eine eigene Security Group die man nicht
selbst erstellt -- die muss man kennen und verwenden, sonst gehen die
Regeln ins Leere."

---

## CloudFront + ALB brauchen separate ACM Certs

- **CloudFront** ist ein globaler Service und verlangt sein SSL-Zertifikat
  in **us-east-1** (Virginia) -- egal wo deine App laeuft
- **ALB** ist ein regionaler Service und braucht sein Zertifikat in der
  **gleichen Region** wie der ALB -- bei dir **eu-central-1** (Frankfurt)

Das sind **zwei separate Zertifikate** fuer die gleiche Domain. Beide
kostenlos ueber ACM. Aber wenn du nur eins erstellst, fehlt dem anderen
Service das Cert und HTTPS geht nicht.

**Einfach gesagt:** "Globale und regionale AWS-Services leben in
unterschiedlichen Welten -- selbst fuer die gleiche Domain braucht man
zwei Zertifikate."

---

## Tailscale DNS blockiert externe Domain-Aufloesung

Tailscale hat einen eigenen DNS-Resolver (100.100.100.100) fuer MagicDNS --
damit kannst du Tailscale-Geraete ueber Namen ansprechen (z.B. nas).

**Das Problem:** Dieser DNS kennt nur Tailscale-interne Namen. Wenn du
`blog.aws.his4irness23.de` aufrufst, fragt dein Mac den Tailscale-DNS,
und der sagt "kenn ich nicht". Normalerweise wuerde er an einen
oeffentlichen DNS weiterleiten, aber das klappt nicht immer zuverlaessig.

**Fix:** In der Tailscale-App "Use Tailscale DNS settings" deaktivieren,
oder manuell DNS auf 8.8.8.8 setzen.

**Einfach gesagt:** "VPN-DNS und Custom-Domains vertragen sich nicht
automatisch -- eine Debugging-Falle die man einmal kennen muss."

---

## Auth Dev-Mode Bypass

Das Backend prueft beim Start ob COGNITO_USER_POOL_ID gesetzt ist.
Wenn nicht (lokale Entwicklung), ueberspringt die Auth-Middleware die
JWT-Validierung und setzt einen Mock-Admin-User. So kann man lokal
entwickeln ohne ein laufendes Cognito zu brauchen.

Das ist ein Standard-Pattern: Produktions-Auth mit Dev-Bypass. Wichtig
ist dass der Bypass NUR greift wenn die Env-Variable fehlt -- in
Produktion ist sie immer gesetzt.

---

## Checkov Triage: Beheben, Unterdruecken oder Aufschieben

Checkov prueft Terraform gegen AWS Best Practices und meldet Findings.
Fuer jedes Finding gibt es drei Optionen:

1. **Fix** -- das Finding ist berechtigt, Code aendern
   - Beispiel: copy_tags_to_snapshot fehlte bei RDS -> gefixt
2. **Suppress** -- bewusste Entscheidung, mit Begruendung dokumentieren
   - Beispiel: kein Multi-AZ RDS weil Dev-Umgebung -> checkov:skip + Kommentar
3. **Defer** -- spaeter entscheiden (bei dir: 0 deferred, alles adressiert)

**Ergebnis: 142 passed, 3 fixed, 39 suppressed, 0 deferred.**
Jeder einzelne Finding wurde explizit bewertet -- nichts wurde ignoriert.

---

## Comprehend: Deutsche Ironie/Sarkasmus

Amazon Comprehend analysiert Sentiment (Stimmung) von Texten. Bei
deutschem Sarkasmus versagt es:

- "Ganz schoen ueberzogen dargestellt!" -> POSITIVE 100%
  (Das Wort "schoen" triggert den Positive-Detektor)
- "Das stimmt so nicht." -> NEGATIVE 72% (korrekt)

Comprehend erkennt keine Ironie oder Sarkasmus auf Deutsch. Das ist
eine bekannte Einschraenkung von NLP-Modellen. Deshalb bleibt manuelle
Moderation neben der Auto-Moderation Pflicht.

**Guter Punkt fuer die Praesentation:** Zeigt dass man die Grenzen von
AWS-Services kennt und ehrlich damit umgeht, statt sie zu verschweigen.

---
---

# Cheatsheet -- K8s Manifeste & Security Groups

## Die 12 Manifeste auf einen Blick

| # | Datei | Was es tut |
|---|-------|------------|
| 00 | namespace.yaml | Erstellt den Bereich `blog` -- alle Blog-Ressourcen leben isoliert hier drin |
| 01 | configmap.yaml | Nicht-geheime Config (Port, Region, CORS-URL) -- wird von Backend-Pods gelesen |
| 02 | secrets.yaml | Geheime Werte (DB-URL, Cognito-IDs) -- Platzhalter die die Pipeline mit echten Werten fuellt |
| 03 | backend-deployment.yaml | Startet 2 Backend-Pods (Express API), verteilt auf 2 AZs, laeuft als Non-Root User |
| 04 | backend-service.yaml | Gibt dem Backend eine interne Adresse -- heisst `backend` damit nginx es per Name findet |
| 05 | frontend-deployment.yaml | Startet 2 Frontend-Pods (nginx), mountet die Admin-Config als Volume |
| 06 | frontend-service.yaml | Gibt dem Frontend eine interne Adresse fuer den ALB |
| 07 | ingress.yaml | Der Eingang von aussen -- erstellt den ALB mit HTTPS, leitet Traffic ans Frontend |
| 08 | db-init-configmap.yaml | Enthaelt die SQL-Scripts (Schema + 11 Blog-Posts) als ConfigMap-Daten |
| 09 | db-init-job.yaml | Einmal-Job: startet einen postgres-Container der die SQL-Scripts gegen RDS ausfuehrt |
| 10 | hpa.yaml | Auto-Scaling: Backend 1-4 Pods, Frontend 1-3 Pods, basierend auf CPU-Last |
| 11 | grafana-dashboard.yaml | Grafana-Dashboard-JSON fuer AWS ML Services (Translate, Polly Metriken) |

## Zusammenhaenge als Kette

```
00 Namespace        <- alles andere lebt hier drin
    |
01 ConfigMap -----> 03 Backend Deployment <- liest Config + Secrets
02 Secrets -------> 03 Backend Deployment
    |                    |
    |               04 Backend Service    <- interner Name "backend"
    |                    ^
    |                    | (nginx proxy_pass: backend:3000)
    |                    |
05 Frontend Depl.  -> 06 Frontend Service <- interner Name "frontend"
    |                    ^
    |                    | (ALB routet hierhin)
    |                    |
    |               07 Ingress            <- erstellt den ALB, HTTPS, oeffentlich
    |
08 DB ConfigMap --> 09 DB Init Job        <- einmal SQL ausfuehren, dann fertig
02 Secrets -------> 09 DB Init Job        <- braucht DATABASE_URL
    |
10 HPA             <- ueberwacht 03 + 05, skaliert Pods hoch/runter
    |
11 Grafana Dashboard <- lebt in namespace "monitoring", nicht "blog"
```

## Die 6 wichtigsten Verbindungen

1. **Config -> Pods:** ConfigMap (01) und Secrets (02) werden in die Deployments (03, 05) injected -- Code liest nur Env-Variablen, nie hardcoded Werte
2. **Service -> Service:** Frontend-nginx macht `proxy_pass http://backend:3000` -- der Name `backend` ist der Service-Name aus 04. Deshalb muss der Service exakt so heissen
3. **Ingress -> Service:** Der ALB (07) routet Traffic an den Frontend-Service (06) -- mit `target-type: ip` direkt auf Pod-IPs, nicht ueber NodePort
4. **HPA -> Deployment:** Der HPA (10) ueberschreibt die `replicas` Zahl der Deployments (03, 05) -- er hat das letzte Wort
5. **Job ist einmalig:** DB-Init (09) laeuft einmal, fuellt die Datenbank, und raeumt sich nach 5 Minuten selbst auf
6. **Grafana (11) lebt woanders:** Im `monitoring` Namespace, nicht in `blog` -- Grafana entdeckt das Dashboard automatisch ueber ein Label

## SG/ALB Problem und Loesung

**Das Problem:** Terraform erstellt Security Groups, aber EKS erstellt automatisch eine eigene Cluster-SG. Pods kommunizieren ueber die Cluster-SG -- eigene Terraform-Regeln greifen ins Leere.

**Die Loesung:** Die eigene Node-SG wird dem Cluster mitgegeben (`security_group_ids`). EKS haengt dann beide SGs an die Nodes -- seine Cluster-SG plus unsere Custom-SG. Damit greifen unsere Regeln.

**Beim ALB:** Der ALB wird nicht von Terraform erstellt, sondern vom AWS Load Balancer Controller in K8s. Die Verbindung laeuft ueber Annotations im Ingress-Manifest -- die Pipeline fuellt die ALB-SG-ID aus dem Terraform-Output ein.

**Traffic-Kette mit Security Groups:**
```
Internet -> ALB        (ALB-SG: Port 80/443 von ueberall)
         -> EKS Nodes  (Node-SG: Port 80 nur von ALB-SG)
         -> RDS         (RDS-SG: Port 5432 nur von Node-SG)
```

**Einfach gesagt:** "Terraform erstellt die Regeln, Kubernetes erstellt den ALB -- die Pipeline verbindet beide Welten ueber Annotations und Terraform-Outputs."
