Feature: MISP OIDC Authentication

  Scenario: Anmeldung an MISP über OIDC-Provider
    Given ich habe ein Kubernetes-Cluster mit MISP installiert
    And die Helm-Values enthalten folgende Werte:
      | key                           | value                                                       |
      | auth.oidc.enabled             | true                                                        |
      | auth.oidc.provider_url        | https://key.zeus:32443/realms/SIEM-Application             |
      | auth.oidc.custom_logout_url   | https://key.zeus:32443/realms/SIEM-Application/protocol/openid-connect/logout |
      | auth.oidc.client_id           | misp                                                        |
      | auth.oidc.roles_property      | misp-roles                                                  |
      | auth.oidc.roles_mapping       | {"misp-admin": "1", "misp-user": "3", "misp-publisher": "4"} |
      | auth.oidc.default_org         | example                                                     |

    When ich die MISP-Login-Seite aufrufe
    And sehe ich die Anmeldemaske des OIDC providers
    And ich gebe meine OIDC-Anmeldedaten ein
    Then sollte die Anmeldung erfolgreich sein
    And ich sollte Zugriff auf das MISP Dashboard haben


Feature: MISP Authentication Configuration

  Scenario: Anmeldung an MISP mit automatisch generiertem Passwort
    Given ich habe ein Kubernetes-Cluster mit MISP installiert
    And die Helm-Values enthalten folgende Werte:
      | key                  | value  |
      | auth.oidc.enabled    | false  |
      | vault.enabled        | false  |
      | auth.adminEmail      | admin@example.com |
    When ich das Passwort aus dem Secret "misp-secrets" unter dem Key "password" auslese
    And ich versuche mich mit "admin@example.com" und dem ausgelesenen Passwort an MISP anzumelden
    Then sollte die Anmeldung erfolgreich sein
    And ich sollte Zugriff auf das MISP Dashboard haben

Feature: Initial Tags Creation in MISP

  Scenario: Automatische Erstellung von Tags bei aktivierter InitTags-Funktion
    Given ich habe ein Kubernetes-Cluster mit MISP installiert
    And die Helm-Values enthalten folgende Werte:
      | key                                 | value  |
      | mispConfig.createInitTags.enabled  | true   |
      | mispConfig.createInitTags.tags[0].name  | tlp:white  |
      | mispConfig.createInitTags.tags[0].color | #FFFFFF    |
      | mispConfig.createInitTags.tags[0].exportable | true |

    When ich mich mit gültigen Admin-Zugangsdaten an MISP anmelde
    And ich navigiere zu "Event Actions" → "List Tags"
    Then sollte ich in der Liste den Tag "tlp:white" mit der Farbe "#FFFFFF" und Exportable "true" sehen

Feature: MISP Backup Configuration

  Scenario: Sicherstellen, dass das Backup korrekt konfiguriert wird
    Given ich habe ein Kubernetes-Cluster mit MISP installiert
    And die Helm-Values enthalten folgende Werte:
      | key                               | value      |
      | backup.enabled                    | true       |
      | backup.debug                      | false      |
      | backup.backupRetentionCount       | 2         |
      | backup.successfulJobsHistoryLimit | 3         |
      | backup.failedJobsHistoryLimit     | 1         |
      | backup.ttlSecondsAfterFinished    | 3600      |
      | backup.schedule                   | 0 0 * * * |

    When ich die erstellten Backup-Jobs überprüfe
    Then sollte ein CronJob mit dem Zeitplan "0 0 * * *" existieren (Wird erst beim ersten ausführen erstellt)
    And das erfolgreiche erstellen des Backups kann im Log des Jobs/Pods gesehen werden
    And es sollten maximal 3 erfolgreiche Backup-Jobs in der History gespeichert werden
    And es sollte maximal 1 fehlgeschlagener Backup-Job in der History gespeichert werden
    And abgeschlossene Backup-Jobs sollten nach 3600 Sekunden gelöscht werden

Feature: Überprüfung der Benutzererstellung in MISP
  
  Scenario: Ein neu erstellter Benutzer ist in der Benutzerliste sichtbar
    Given alle MISP Pods sind "READY"
    When ich mich mit einem administrativen Benutzer in MISP einlogge
    And ich auf "Administration -> List Users" klicke
    Then sollte der Benutzer "nofallnutzer@misp.local" in der Liste sichtbar sein
