# Crypto-Miner auf meinem Server: Wie ich den Angriff erkannt und gestoppt habe

**Kategorie:** Networking & Security | **Featured:** Nein | **Lesezeit:** 6 Min | **Datum:** 2026-03-05

**Excerpt:** Die NAS neben mir wird plötzlich ohrenbetäubend laut, Telegram meldet CPU-Auslastung über 200 Prozent. In unter drei Minuten war der Verursacher identifiziert und isoliert. Wie mein Monitoring-Stack einen echten Angriff erkannt hat — und was schnelle Reaktion wirklich bedeutet.

---

## NAS auf Maximum, Telegram vibriert

Ich sitze am Schreibtisch, die NAS steht eine Armlänge entfernt. Normalerweise ist sie kaum hörbar. Dann, von einer Sekunde auf die nächste, dreht sie komplett auf. Lüfter auf Maximum, ein Geräusch, das ich so noch nie gehört habe. Mein erster Gedanke: Da stimmt etwas nicht.

Gleichzeitig vibriert mein Handy. Telegram. Grafana-Alert: CPU-Auslastung über 200 Prozent. Mehrere Werte im kritischen Bereich.

---

## Ruhe bewahren, systematisch vorgehen

Kein Panik-Modus. Ich öffne das Grafana-Dashboard und sehe sofort: Die CPU-Last ist nicht graduell gestiegen, sondern schlagartig explodiert. Das ist kein normaler Workload. Das ist entweder ein defekter Container oder etwas, das dort nicht hingehört.

Also systematisch vorgehen: Welche Container laufen, welche Prozesse verursachen die Last, was hat sich in den letzten Stunden verändert? Der Scan zeigt schnell ein eindeutiges Bild. Ein Container, den ich etwa zwei bis drei Stunden vorher reaktiviert hatte, verursacht die gesamte Last.

Es war ein alter Blog-Container — ein frühes Projekt aus den ersten Monaten meiner Weiterbildung, das ich nach längerer Pause wieder hochgefahren hatte, um an alte Inhalte zu kommen. In der Zwischenzeit hatte jemand eine offene Datenbankverbindung in diesem Container als Einstiegspunkt genutzt und einen Crypto-Miner gestartet. Die NAS rechnete mit voller Leistung für jemand anderen.

Container isoliert, gestoppt, entfernt. Unter drei Minuten von der ersten Meldung bis zur Entschärfung.

---

## Die Schwachstelle: Altlast aus der Lernphase

Die retrospektive Analyse hat gezeigt: Der Container stammte aus einer Phase, in der ich gerade erst angefangen hatte, mit Datenbanken zu arbeiten. Damals war in der MongoDB-Konfiguration ein Workaround für ein lokales Connection-Problem gesetzt worden — eine Einstellung, die in der Entwicklungsumgebung funktioniert hat, aber nie für den Dauerbetrieb gedacht war.

Der Container war monatelang deaktiviert, das Projekt eingefroren, andere Prioritäten hatten übernommen. Als ich ihn Monate später reaktivierte, war die alte Datenbank-Konfiguration noch aktiv — und innerhalb weniger Stunden hatte jemand sie gefunden.

Das Internet wird systematisch nach offenen Datenbanken gescannt. Wer eine ungesicherte Verbindung exponiert, wird gefunden. Nicht in Wochen, nicht in Tagen — in Stunden.

---

## Bereinigung und Härtung

Nach der unmittelbaren Entschärfung habe ich das Ganze gründlich aufgearbeitet:

- Datenbank komplett abgesichert, Zugriff auf localhost beschränkt
- Sämtliche Credentials rotiert — nicht nur die betroffenen, sondern alle
- Den alten Container und seine Konfiguration vollständig entfernt
- Alle laufenden Container auf ähnliche Altlasten geprüft

Am Ende stand die Gewissheit: Keine weiteren offenen Flanken, keine Spuren des Miners außerhalb des isolierten Containers. Der Angriff war auf diesen einen Container begrenzt — und genau dort lag er auch keine drei Minuten später bereits still.

---

## Warum Monitoring den Unterschied macht

Das ist der eigentliche Punkt dieses Posts. Nicht der Angriff selbst — sondern was davor bereits existierte.

Ich war zuhause und habe die NAS gehört. Aber was, wenn ich nicht zuhause gewesen wäre? Was, wenn das nachts passiert wäre oder unterwegs?

Genau dafür steht das Monitoring. Der Grafana-Alert wäre trotzdem gekommen. Auf Telegram, auf mein Handy, egal wo ich bin. Ich hätte den CPU-Spike gesehen, hätte mich remote über Tailscale verbinden können und hätte den Container auch von unterwegs stoppen können. Die Reaktionszeit wäre vielleicht nicht drei Minuten gewesen, aber es wären Minuten geblieben — nicht Stunden oder Tage.

Ohne Alerting hätte der Miner möglicherweise so lange laufen können, bis die Hardware Schaden nimmt. Bei über 200 Prozent CPU-Auslastung und der Hitzeentwicklung, die ich in den Metriken gesehen habe, bin ich nicht sicher, wie lange die NAS das mitgemacht hätte.

Das Monitoring stand. Der Alert kam innerhalb von Sekunden. Und weil ich wusste, wo ich nachschauen muss — Grafana für die Übersicht, Container-Metriken für die Eingrenzung — war der Verursacher in Minuten identifiziert. Das ist der Return on Investment für jeden Service, den ich in den Monaten davor aufgesetzt habe.

---

## Lektionen für die Zukunft

**Alte Konfigurationen leben weiter.** Ein Container, der monatelang deaktiviert war, trägt seine Konfiguration mit. Wer einen alten Service reaktiviert, muss ihn vorher prüfen — nicht nur ob er läuft, sondern ob er sicher ist. Das ist seitdem Standard bei mir.

**Das Netz vergisst nicht und schläft nicht.** Offene Datenbanken, exponierte Ports, ungesicherte Services — sie werden aktiv und automatisiert gescannt. Wenige Stunden reichen.

**Ohne Monitoring bleibt ein Angriff unsichtbar.** Es ist die Grundlage dafür, dass man ihn in Minuten erkennt statt in Tagen.

**Strukturiertes Vorgehen zahlt sich aus.** Erkennen, eingrenzen, isolieren, bereinigen, aufarbeiten. Kein hektisches Abschalten, kein Neuinstallieren ohne Plan.

Rückblickend bin ich froh, dass es passiert ist. Nicht weil ein Angriff auf die eigene Infrastruktur erstrebenswert wäre — sondern weil es die Bestätigung war, dass das Monitoring funktioniert, die Reaktion sitzt und der eingeschlagene Weg der richtige ist.

Das ist keine Theorie mehr. Das ist Praxis.

---

**Nächster Post:**
AWS Solutions Architect: Warum ich die Prüfung mit Praxis statt nur Theorie vorbereitet habe.
