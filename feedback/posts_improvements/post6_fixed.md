# EcoKart: Mein erster vollständiger Webshop auf AWS

**Kategorie:** AWS & Cloud | **Featured:** Ja | **Lesezeit:** 7 Min | **Datum:** 2026-02-26

**Excerpt:** Ein Kurs-Rechercheprojekt über Infrastruktur-Kosten brachte mich auf die Idee, einen echten Webshop auf AWS zu bauen. 12 Services, 15 Terraform-Module, Stripe-Zahlungen, Cognito-Authentifizierung -- und eine Email-Provider-Odyssee, die mich am Neujahrstag bei Resend landen ließ.

---

## Von Kostenvergleich zu eigenem Shop

Der Anstoß für EcoKart kam aus einer Gruppenarbeit in der Weiterbildung. Die Aufgabe war rudimentär: verschiedene Infrastruktur-Ansätze gegenüberstellen -- Serverless vs. EC2, managed vs. self-hosted -- und bewerten, welche Architektur für welche Anforderung sinnvoll ist. Welche Kosten entstehen, welche Vor- und Nachteile gibt es. Rein theoretisch, ohne Umsetzung.

Aber die Recherche hat etwas ausgelöst. Ich habe mir die verschiedenen Architekturen angeschaut und gedacht: Wie lerne ich das wirklich, wenn ich es nie umsetze? Wie verstehe ich AWS-Services in der Praxis, wenn ich nur Tabellen mit Kostenvergleichen fülle?

Also habe ich mir einen konkreten Use Case gesucht: einen vollständig serverlosen Webshop. Mit dem Ziel, die geringstmöglichen Kosten zu verursachen und trotzdem alles mitzubringen, was ein echter Shop braucht -- Produkte, Warenkorb, Zahlungsabwicklung, Benutzerverwaltung, Bestellbestätigung per Email. Von Anfang an als Showcase für spätere Bewerbungen gedacht. Nicht als Kursaufgabe, sondern als echtes Lernprojekt.

---

## Die Architektur

Serverless war gesetzt. Kein EC2, kein dauerhaft laufender Server. Stattdessen: AWS Lambda für die gesamte Backend-Logik, DynamoDB als Datenbank, API Gateway als Schnittstelle, Amplify für das Frontend. Dazu S3 und CloudFront für Produktbilder, Cognito für die Authentifizierung, Route53 für Custom Domains, ACM für SSL-Zertifikate, CloudWatch für Monitoring.

12 AWS-Services insgesamt, verteilt auf 15 Terraform-Module. Die monatlichen Kosten: ungefähr 10 bis 15 Dollar. Das war einer der entscheidenden Punkte für Serverless -- man zahlt nur, was man tatsächlich nutzt. Kein Leerlauf, keine Grundgebühr für laufende Instanzen. Genau das, was ich in der Gruppenarbeit theoretisch verglichen hatte, konnte ich jetzt in der Praxis bestätigen.

Die gesamte Infrastruktur ist in Terraform definiert. Jedes Modul hat seine eigene Verantwortung -- Cognito, DynamoDB, Lambda, Amplify, und so weiter. Ich kann den kompletten Shop in etwa 15 Minuten von Null aufbauen. Oder in Minuten zerstören und neu deployen.

---

## OIDC: Keine Keys im Repository

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

## Cognito: Authentifizierung, die sich gewehrt hat

Für die Benutzerverwaltung habe ich mich für AWS Cognito entschieden. Die Idee war einfach: Benutzer registrieren sich, bestätigen ihre Email, bekommen ein JWT-Token und authentifizieren sich damit bei der API.

Die Umsetzung war alles andere als einfach. Cognito hat viele Stellschrauben, und die Dokumentation ist nicht immer intuitiv. Token-Handling, Refresh-Logik, Custom Attributes für Rollen, Email-Verifizierung mit sechsstelligen Codes -- jedes dieser Themen war eine eigene Baustelle.

Am Ende funktioniert es: Registrierung, Login, rollenbasierter Zugriff und ein Admin-Dashboard. Aber es war die aufwendigste Lernkomponente des gesamten Projekts.

---

## Stripe: Stabile Endpoints erzwingen

Für die Zahlungsabwicklung habe ich Stripe integriert. Der Kunde wird zum Checkout weitergeleitet, gibt seine Kartendaten ein und nach erfolgreicher Zahlung schickt Stripe einen Webhook an meine Lambda-Funktion. Die erstellt die Bestellung in DynamoDB.

Ein Problem blieb lange bestehen: Nach jedem `terraform destroy` und neuem Deploy bekam die API einen neuen Endpoint. Damit war die Webhook-URL bei Stripe jedes Mal kaputt.

Die Lösung waren Custom Domains über Route53 und ein ACM-Zertifikat. Damit blieb der Stripe-Endpoint stabil, egal wie oft ich die Infrastruktur neu aufgebaut habe. Gleichzeitig liefen auch Webshop, Adminbereich und API unter festen URLs.

---

## Email-Odyssee: Neujahr bei Resend

Ein Webshop ohne Bestellbestätigung per Email ist kein richtiger Webshop. AWS SES war der naheliegende Weg.

Im Sandbox-Modus funktionierte SES auch, aber für echte Nutzer braucht man den Production-Modus. Antrag gestellt. Abgelehnt. Also ein externer Anbieter: SendGrid. Ebenfalls abgelehnt.

Zwei Ablehnungen hintereinander, und ich konnte das Problem erst nicht greifen. Irgendwann habe ich verstanden, woran es liegt: Sowohl AWS als auch SendGrid sind bei ganz neuen Accounts extrem vorsichtig. Kein Versand-Verlauf, kein Vertrauen. Das ist eine Spam-Schutzmaßnahme, die erst mal jeden trifft, der frisch anfängt.

Die Lösung kam am 1. Januar 2026. Neujahrsmorgen, und ich sitze an der Email-Integration. Ich hatte von Resend gehört -- ein neuerer Email-Service, der sich explizit an Entwickler richtet. Account erstellt, Domain verifiziert, API-Key generiert, Code angepasst. 90 Minuten später verschickte EcoKart die erste Bestellbestätigung.

Die Lektion: Nicht ewig kämpfen, sondern Alternativen evaluieren. Die Migration hat 90 Minuten gedauert. Das Warten auf die SES-Freischaltung hätte ewig dauern können.

---

## Testing

Ein Webshop, der Zahlungen verarbeitet und Benutzerdaten verwaltet, muss getestet sein.

63 Tests mit Jest, aufgeteilt in Unit- und Integrationstests. Was mir beim Testen am meisten gebracht hat, war das Denken in Fehlerfällen. Nicht nur "funktioniert der Warenkorb", sondern: Was passiert, wenn ein Nutzer versucht, die Bestellung eines anderen Nutzers abzurufen? Die Antwort muss ein 403 sein, kein 404 -- weil der Nutzer wissen soll, dass die Ressource existiert, er aber keinen Zugriff hat. Solche Unterscheidungen lernt man erst, wenn man sie tatsächlich testet.

Die Integrationstests laufen über LocalStack -- eine lokale Emulation von AWS-Services. Damit kann ich den kompletten Flow testen: Produkt in den Warenkorb, Bestellung auslösen, prüfen ob der Lagerbestand korrekt reduziert wurde, über alle vier DynamoDB-Tabellen hinweg. Kein Mocking, sondern echte Datenbankoperationen.

In der CI/CD Pipeline laufen die Tests automatisch bei jedem Push. Kein Deployment ohne grüne Tests.

---

## Was ein eigenes Projekt wirklich lehrt

EcoKart hat mir mehr über AWS beigebracht als jeder Kurs. Nicht weil der Kurs schlecht wäre -- sondern weil ein eigenes Projekt Probleme erzeugt, die in keinem Tutorial stehen.

12 AWS-Services. 15 Terraform-Module. Ein Shop, der Bestellungen annimmt, Zahlungen verarbeitet, Bestätigungen verschickt und sich in etwa 15 Minuten vollständig reproduzieren lässt.

Das ist kein Kursprojekt mehr. Das ist Praxiserfahrung.

---

**Nächster Post:**  
Das große Bild: Wie aus einzelnen Projekten eine Hybrid-Infrastruktur mit über 50 Services wurde.
