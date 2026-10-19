# AKS bei Bedarf starten — Kostenalternative

Stand: 19.10.2026. Vorschlag, noch nicht bereitgestellt und noch keine Kostenfreigabe erhalten.

Der vorbereitete Zwei-Node-AKS muss nicht durchgehend laufen. Nach Installation und Validierung kann der gesamte Cluster mit `az aks stop` gestoppt werden. Fuer Vorfuehrungen wird er mit `az aks start` gestartet. Die bestehende Broker-VM wird dadurch nicht gestoppt.

## Planungskosten

Node-Rechenpreis aus der Preisabfrage: 2 x USD 0.2134 = USD 0.4268 je laufender Clusterstunde, einschliesslich Installation, Tests und Vorlauf. Keine Preisgarantie; Steuer, Wechselkurs und MuleSoft-Lizenzen ausgeschlossen.

| Nutzung des zusaetzlichen AKS | Planung |
|---|---|
| Rund um die Uhr | Bisheriger Rahmen USD 350–390/Monat |
| Ganzen Monat gestoppt, Ressourcen bleiben bestehen | Fuer Disks und ggf. weiter bestehende Netzwerk-/Zustandsressourcen vorsichtig USD 40–80/Monat zurueckstellen; konkreten Restbetrag anhand der tatsaechlichen Ressourcen pruefen |
| Beispiel 40 aktive Stunden im Monat | USD 17.07 Node-Rechenzeit plus Restressourcen; vorsichtiger Rahmen USD 57–97/Monat |

Die Restkostenschaetzung ist ein Budgetpuffer, keine verifizierte Rechnung fuer einen gestoppten Cluster. Der Free-Tier-Verwaltungspreis macht persistente Disks und Netzwerkressourcen nicht kostenlos. Keine bezahlten Zusatzdienste oder neuen Monitoring-Plaene einschalten. Terraform-Zustand muss ausserhalb kurzlebiger Provider-Prozesse sicher erhalten bleiben und kann weitere kleine Speicherkosten verursachen.

## Vorgehen nach ausdruecklicher Freigabe

1. Quota-/SKU-/Versions-/Berechtigungspruefung und Terraform-Plan abschliessen.
2. Cluster aufbauen und GitOps-Komponenten validieren.
3. Ergebnisse und Zugangs-/Wiederanlaufanleitung sichern.
4. Gesamten Cluster ueber die AKS-API stoppen und `powerState.code == Stopped` nachpruefen. Nicht einzelne AKS-VMs manuell deallozieren.
5. Spaeter vor einer Demo starten und Nodes, Controller und die konkrete Anwendung erneut pruefen. Fuer Start und Pruefungen ausreichend Vorlauf einplanen.
6. Nach der Demo wieder stoppen und den Zustand pruefen. Es wurde noch kein automatischer Zeitplan eingerichtet; ein vergessener Stopp verursacht laufende Compute-Kosten.

Bedienbefehle nach erfolgreicher Bereitstellung, mit expliziter Subscription:

```powershell
az aks stop --subscription 6f5e5d9c-cd3f-4dec-8ade-410c01c8195f --resource-group 'flughafen-zürich-poc' --name aks-fzag-runtime
az aks show --subscription 6f5e5d9c-cd3f-4dec-8ade-410c01c8195f --resource-group 'flughafen-zürich-poc' --name aks-fzag-runtime --query '{power:powerState.code,provisioning:provisioningState}'
az aks start --subscription 6f5e5d9c-cd3f-4dec-8ade-410c01c8195f --resource-group 'flughafen-zürich-poc' --name aks-fzag-runtime
```

Auf dem neuen Cluster sind zunaechst keine Gateways oder Argo-/Crossplane-Controller enthalten. Spaeter darauf installierte Workloads/Controller laufen im gestoppten Zustand ebenfalls nicht. Eine kuenftige Anypoint-SaaS-Verwaltung laeuft davon unabhaengig weiter.

Microsoft dokumentiert, dass Clusterzustand bis zu 12 Monate erhalten bleibt. Vor Neustart nach einem Stopp 15–30 Minuten fuer das vollstaendige Stoppen abwarten; die eigentliche Startdauer ist davon getrennt. Start kann bei fehlender regionaler VM-Kapazitaet fehlschlagen. Deshalb nicht unmittelbar vor dem Praesentationstermin starten.

Fuer praktisch keine AKS-Restkosten waere vollstaendiges Loeschen und spaeteres Neuaufbauen noetig. Das ist ein eigener destruktiver Vorgang mit Freigabe und erfordert einen getesteten Wiederaufbau inklusive Secrets/Zustand; das ist nicht Bestandteil dieses Stop-/Start-Vorschlags.

Quelle: https://learn.microsoft.com/en-us/azure/aks/start-stop-cluster
