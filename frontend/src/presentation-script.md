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
- **Deployment** = sagt Kubernetes: "Ich will 2 Backend-Pods und 1 Frontend-Pod, halte die am Laufen"
- **Service** = interne Adresse damit sich Pods gegenseitig finden koennen
- **Ingress** = der Eingang von aussen -- verbindet den ALB Load Balancer mit den Pods
- **HPA** = Horizontal Pod Autoscaler -- wenn CPU ueber 70% geht, werden automatisch mehr Pods gestartet
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
- Backend 2 Replicas, Frontend 1-2

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
- Warten bis Backend von 2 auf 3-4 Pods skaliert (~60s)
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
