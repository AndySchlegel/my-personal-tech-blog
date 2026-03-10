# Diesen Blog auf AWS EKS deployen: Mein Abschlussprojekt

**Kategorie:** AWS & Cloud | **Featured:** Ja | **Lesezeit:** 7 Min | **Datum:** 2026-03-12

**Excerpt:** Das Abschlussprojekt meiner Weiterbildung: Diesen Tech-Blog als Cloud-Native Anwendung auf AWS EKS bauen. Neun Terraform-Module, sechs CI/CD-Pipelines, OIDC statt AWS-Keys und eine Wave-Strategie, die Kosten kontrollierbar macht. Überdimensioniert für einen Blog — aber genau darum ging es.

---

## Ein Blog mit Zukunft

Am Ende der Weiterbildung steht ein Abschlussprojekt: eine produktionsreife, cloud-native Anwendung auf AWS. Vier Wochen Zeit, klare technische Anforderungen — EKS, Terraform, CI/CD, Datenbank, Authentifizierung, ML-Service. Die Projektidee war freigestellt, solange die Rahmenbedingungen erfüllt sind.

Meine Entscheidung: diesen Tech-Blog. Nicht weil ein Blog die technisch anspruchsvollste Anwendung ist, sondern weil ich etwas bauen wollte, das über das Abschlussprojekt hinaus einen Zweck hat. Ein Showcase, den ich in Bewerbungen verlinken kann. Der den Fortschritt zeigt, den ich in den letzten Monaten gemacht habe — und gleichzeitig alle technischen Anforderungen der Aufgabe abdeckt.

---

## Warum EKS

Es gab zwei Optionen: EKS oder Serverless mit Lambda. Für einen Blog wäre Serverless die kosteneffizientere Wahl gewesen. EKS ist für diese Anwendung überdimensioniert — und genau das war der Punkt.

Kubernetes ist in der Praxis Standard für komplexe Webanwendungen. Unternehmen betreiben ihre Plattformen auf EKS, und wer dort arbeiten will, muss verstehen, wie Deployments, Services, Ingress und Pod-Scheduling zusammenspielen. Nicht nur theoretisch, sondern hands-on: Manifeste schreiben, Probleme debuggen und Konfigurationen iterieren.

Die Serverless-Architektur kannte ich bereits aus EcoKart. EKS war die Gelegenheit, die andere Seite kennenzulernen — und bewusst die Variante zu wählen, die näher an Enterprise-Setups liegt.

---

## 9 Terraform-Module

Die Infrastruktur besteht aus neun Terraform-Modulen:

**Netzwerk und Security:** Eigene VPC mit Public und Private Subnets über zwei Availability Zones. Security Groups nach dem Prinzip der minimalen Rechte — der ALB akzeptiert Traffic aus dem Internet, die EKS-Nodes nur vom ALB, die Datenbank nur von den Nodes. Kein direkter öffentlicher Zugriff auf irgendetwas außer dem Load Balancer.

**EKS-Cluster:** Managed Control Plane mit einer Node Group auf Spot Instances. Zwei Nodes im Betrieb, skalierbar zwischen eins und drei. Spot Instances sparen gegenüber On-Demand erheblich — für ein Portfolio-Projekt ein akzeptabler Trade-off, weil kurzzeitige Unterbrechungen verschmerzbar sind.

**Datenbank:** RDS PostgreSQL in Private Subnets, verschlüsselt, automatische Backups, nicht aus dem Internet erreichbar. Für die Entwicklung pausierbar, um Kosten zu sparen.

**Frontend und Backend:** Das Frontend ist eine statische Anwendung auf Nginx, das Backend eine Express-API mit TypeScript. Beide laufen als Container in EKS, jeweils mit zwei Replicas, Health Probes und Resource Limits. Pod Anti-Affinity sorgt dafür, dass Replicas auf verschiedene Nodes verteilt werden.

**CDN und DNS:** CloudFront vor S3 für Blog-Assets, mit Origin Access Control — kein öffentlicher S3-Zugriff. ACM-Zertifikat für HTTPS, Route 53 für DNS.

**Authentifizierung:** Cognito User Pool mit OAuth 2.0 für den Admin-Bereich. Optionale MFA, rollenbasierte Zugriffskontrolle.

**ML-Integration:** AWS Comprehend für automatische Sentiment-Analyse von Kommentaren — die ML-Anforderung des Projekts, direkt in den Backend-Flow integriert.

---

## OIDC statt AWS-Keys

Die Projektvorgaben sahen AWS Access Keys als GitHub Secrets vor. Ich habe mich bewusst für OIDC-Federation entschieden — den gleichen Ansatz wie bei EcoKart, aber diesmal von Anfang an eingeplant.

Das Prinzip: GitHub Actions fordert bei jedem Pipeline-Lauf ein kurzlebiges Token an. AWS validiert dieses Token gegen den registrierten OIDC-Provider und stellt temporäre Credentials aus, die nach einer Stunde automatisch ablaufen. Kein Schlüsselpaar, das rotiert werden muss. Kein Risiko, dass langlebige Credentials kompromittiert werden.

Das Ergebnis: Statt vier statischer Secrets braucht das gesamte Projekt nur zwei — die OIDC-Rolle und das Datenbank-Passwort. Alles andere wird dynamisch aus dem Terraform State gelesen.

---

## Sechs Pipelines, ein Workflow

Die CI/CD-Architektur besteht aus sechs GitHub Actions Workflows.

Die **Deploy-Pipeline** durchläuft drei Stufen: Tests, Build, Deployment. Erst wenn alle 31 Tests bestehen, werden die Docker Images gebaut und in ECR gepusht. Erst wenn der Build erfolgreich ist, werden die Kubernetes-Manifeste angewendet. Die Pipeline wartet auf den Rollout und schlägt fehl, wenn Pods nicht starten — kein stilles Ignorieren von Fehlern.

Die **Terraform-Pipeline** steuert die Infrastruktur: Validierung, Security Scans, Plan, Apply oder Destroy. Alles parameterisiert nach Waves und mit Concurrency-Kontrolle, damit nicht zwei Läufe gleichzeitig den State verändern.

Dazu eine **Security-Pipeline** mit drei parallelen Scans: Secrets-Erkennung, Terraform-Security-Checks und Policy-Validierung. Findings blockieren den Merge — kein Durchwinken von bekannten Problemen.

---

## Wave-Strategie: Kosten kontrollieren

EKS kostet. Die Control Plane allein liegt bei rund 73 Dollar im Monat, dazu kommen Nodes, NAT Gateway und Datenbank. Für ein Portfolio-Projekt, das nicht dauerhaft laufen muss, ist das kein tragbares Modell.

Also habe ich die Infrastruktur in Waves aufgeteilt:

**Wave 1** enthält alles, was quasi nichts kostet: VPC, Security Groups, ECR, S3, Cognito, OIDC. Bleibt dauerhaft bestehen.

**Wave 2** fügt die Datenbank hinzu. Rund 13 Dollar im Monat, pausierbar wenn nicht gebraucht.

**Wave 3** ist der Full Stack: EKS, CloudFront, NAT Gateway. Das läuft nur, wenn ich aktiv entwickle oder den Blog demonstrieren möchte. Hochfahren, zeigen, herunterfahren.

Der Kern der Strategie: Alles ist vollständig reproduzierbar. Infrastruktur zerstören und in Minuten wieder aufbauen — weil jede Konfiguration in Terraform liegt und die Deploy-Pipeline alle Werte dynamisch aus dem State liest. Kein manuelles Nachpflegen von Endpoints oder IDs nach einem Rebuild.

---

## Zwei Gleise: EKS für Showcase, Lightsail für Dauerbetrieb

EKS auf AWS war die bewusste Entscheidung für die Enterprise-Perspektive. Managed Control Plane, ALB Controller, IRSA für Service Accounts — das ist das Setup, das in Unternehmen mit komplexen Anwendungen eingesetzt wird. Und genau deshalb bleibt EKS als Showcase-Infrastruktur im Repo: hochfahren, demonstrieren, herunterfahren.

Für den dauerhaften Betrieb des Blogs nutze ich eine Lightsail Instance. Gleicher Code, gleiche Container, aber auf einer einzelnen $5-Maschine statt einem Kubernetes-Cluster. Cognito und Comprehend laufen weiterhin als Managed Services — die bleiben im AWS-Ökosystem. Nur die Hosting-Schicht wird bewusst vereinfacht.

Beide Varianten laufen aus dem gleichen Repository. Separate Terraform-Konfigurationen, separate Deploy-Workflows — per Knopfdruck wählbar. EKS zeigt, dass ich Enterprise-Kubernetes verstehe. Lightsail zeigt, dass ich die richtige Lösung für den jeweiligen Anwendungsfall wählen kann. Und genau diese Abwägung — nicht immer das Größte, sondern das Passende — ist eine der wichtigsten Entscheidungen in der Cloud-Architektur.

---

## Reproduzierbar, nicht einmalig

Was mir an diesem Projekt am wichtigsten ist: Es ist kein einmaliger Aufbau. Alles — vom Netzwerk bis zum letzten Pod — liegt in Code. Terraform für die Infrastruktur, Kubernetes-Manifeste für die Anwendung, GitHub Actions für den Workflow.

Wenn morgen jemand sagt: „Zeig mir, wie du das aufgebaut hast“, kann ich die gesamte Infrastruktur in Minuten hochfahren, den Blog deployen und live demonstrieren. Und danach wieder zerstören, ohne dass etwas verloren geht. Das ist kein theoretisches Versprechen — das ist der Workflow, den ich im Alltag nutze.

Neun Terraform-Module, zehn Kubernetes-Manifeste, sechs Pipelines, 31 Tests. Alles versioniert, alles reproduzierbar, alles transparent im öffentlichen Repository.

---

## Alles zusammen

Dieses Projekt bringt alles zusammen, was in den letzten Monaten entstanden ist. Terraform von EcoKart, Container-Erfahrung aus dem Homelab, CI/CD mit OIDC, Security-First-Denken aus dem Monitoring-Aufbau.

Kein isoliertes Lernprojekt, sondern die Zusammenführung von allem, was ich mir erarbeitet habe.

Und ein Blog, der seinen eigenen Aufbau dokumentiert. Angefangen bei der Frage, warum ich nach fast zwanzig Jahren im Vertrieb noch einmal bei null angefangen habe — bis hierher, wo die Infrastruktur hinter diesem Text genauso Teil der Geschichte ist wie der Text selbst.
