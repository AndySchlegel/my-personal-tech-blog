# Sandbox kaputt, alles weg — wie ich Terraform lieben gelernt habe

**Kategorie:** DevOps & CI/CD | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-02-24

**Excerpt:** Ein Wochenende Arbeit am EcoKart-Webshop, Montagmorgen alles gelöscht. Ein automatischer Cleanup-Workflow in der Sandbox-Umgebung hat jeden Fortschritt entfernt. Der Moment war frustrierend – aber wichtiger war die Frage danach: Wie baut man Infrastruktur so, dass sie jederzeit reproduzierbar ist?

---

## Wenn plötzlich alles weg ist

Das Wochenende war produktiv gewesen. Lambda-Funktionen, DynamoDB, S3, CloudFront – die Architektur stand. Am Sonntagabend lief alles so, wie ich es mir vorgestellt hatte.

Montagmorgen war davon nichts mehr übrig.

Die Sandbox-Umgebung der Weiterbildung hatte über Nacht einen automatischen Cleanup durchgeführt. Kostenlimit überschritten, Umgebung zurückgesetzt – alles gelöscht.

Der erste Moment war Frust. Ein ganzes Wochenende Arbeit verschwunden.

Der zweite Gedanke war wichtiger: Wenn Infrastruktur einfach verschwinden kann, darf ihr Zustand nicht nur in einer laufenden Umgebung existieren.

---

## Der Mindshift

Bis zu diesem Punkt hatte ich Infrastruktur eher schrittweise aufgebaut. Services konfigurieren, Ressourcen anlegen, Dinge ausprobieren, erweitern.

Das funktioniert – solange nichts kaputtgeht.

Sobald jedoch eine komplette Umgebung verschwindet, zeigt sich ein anderes Problem: Wissen steckt plötzlich nur noch im Kopf oder in einzelnen Konfigurationsschritten.

Die eigentliche Frage wurde deshalb schnell klar:

Wie baue ich Infrastruktur so, dass sie jederzeit wiederhergestellt werden kann?

---

## Terraform früher als geplant

Terraform stand zu diesem Zeitpunkt erst später auf dem Lehrplan der Weiterbildung. Der Sandbox-Wipe war für mich der Auslöser, mich schon vorher damit zu beschäftigen.

Ich begann, die EcoKart-Infrastruktur Schritt für Schritt in Terraform nachzubauen. Erst einzelne Ressourcen, dann komplette Services. Dinge, die vorher manuell entstanden waren, wanderten nach und nach in Code.

Das erste Mal `terraform apply` auf eine größere Konfiguration auszuführen und zu sehen, wie komplette Infrastruktur automatisch entsteht, war ein echter Aha-Moment.

Plötzlich ging es nicht mehr darum, eine Umgebung einmal aufzubauen – sondern sie jederzeit reproduzieren zu können.

---

## SCP-Limitierungen: Tod durch tausend Freischaltungen

EcoKart wuchs – und damit kamen neue Probleme. Allerdings nicht technische, sondern organisatorische.

Die Sandbox-Umgebung war durch Service Control Policies eingeschränkt. Bestimmte AWS-Services oder Features waren schlicht gesperrt.

Am Anfang war das noch okay. Aber je weiter das Projekt kam, desto öfter bin ich gegen diese SCP-Wände gelaufen.

ACM-Zertifikate? Gesperrt.  
Custom Domains? Gesperrt.

Der Ablauf war immer derselbe: Anfrage beim Dozenten, erklären warum ich den Service brauche, warten auf Freischaltung. Kaum war eine Limitierung aufgehoben, kam die nächste.

Irgendwann hatte ich das Gefühl, mehr Zeit damit zu verbringen, Freischaltungen zu organisieren als tatsächlich am Projekt zu arbeiten.

---

## Custom Domains: Der Auslöser

Der konkrete Punkt, an dem ich die Entscheidung getroffen habe, war die Stripe-Anbindung.

Ein Webshop braucht eine Zahlungsabwicklung, und Stripe war die logische Wahl. Das Problem: Stripe benötigt stabile Webhook-URLs und Endpoints. In der Sandbox haben sich diese bei jedem Redeploy verändert.

Gleichzeitig wurde mir klar: Das betrifft nicht nur Stripe.

Auch der Webshop selbst, der Adminbereich und die API liefen über rotierende URLs, die sich bei jedem Deployment änderten. Mit Custom Domains würde das alles hinter stabilen, gleichbleibenden Adressen verschwinden.

Keine angepassten Endpoints mehr. Keine wechselnden URLs.

Dafür brauchte ich Custom Domains – und die wiederum brauchten eine SCP-Freischaltung.

An diesem Punkt war klar: Das ergibt keinen Sinn mehr. Ich brauche einen eigenen AWS-Account.

---

## Eigener Account, eigene Verantwortung

Die Entscheidung war bewusst.

Mir war klar, dass ich den gesamten Projektstand migrieren musste – neue AWS Credentials, neue Endpoints, Anpassungen an mehreren Stellen.

Aber genau das war es mir wert.

Ein eigener Account bedeutete: keine SCP-Limitierungen mehr, eigene Kostenverantwortung und vor allem die Möglichkeit, ohne Freischaltungen weiterzulernen.

Und weil EcoKart inzwischen vollständig in Terraform definiert war, war die Migration machbar.

Neuer Account, neue Credentials konfigurieren, `terraform apply` – und die Infrastruktur stand.

Nicht alles war eins zu eins übertragbar. Es gab Anpassungen. Aber die Grundstruktur war da – und das war der Moment, in dem sich die Investition in Terraform zum ersten Mal wirklich ausgezahlt hat.

---

## CI/CD: Alles automatisieren

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

## Reproduzierbar statt einmalig

Mit der Zeit wuchs das Projekt weiter.

15 Terraform-Module.  
12 AWS-Services.  
63 Integrationstests.

Die komplette Infrastruktur ließ sich jederzeit neu aufbauen – und kostete im Dauerbetrieb ungefähr 10 USD pro Monat.

Rückblickend war der Sandbox-Wipe einer der wichtigsten Momente dieser Phase.

Er hat mich gezwungen, Infrastruktur nicht mehr als einmaliges Setup zu sehen, sondern als System, das vollständig beschrieben und jederzeit reproduziert werden kann.

Terraform wurde dadurch zu einem zentralen Werkzeug in meinem Setup.

---

**Nächster Post:**  
EcoKart: Mein erster vollständiger Webshop auf AWS
