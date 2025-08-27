# MISP Docker Image

Dieses Dockerfile erstellt ein Docker-Image für die MISP (Malware Information Sharing Platform). Das Docker-Image basiert auf einer modularen Multi-Stage-Build-Struktur mit Debian Bullseye als Basis. Es enthält verschiedene Abhängigkeiten und Konfigurationen, die für den Betrieb von MISP notwendig sind.

## Inhalt

- [MISP Docker Image](#misp-docker-image)
  - [Voraussetzungen](#voraussetzungen)
  - [Build-Argumente](#build-argumente)
  - [Build-Anweisungen](#build-anweisungen)
  - [Docker Container starten](#docker-container-starten)
  - [Erläuterung der Build-Stages](#erläuterung-der-build-stages)

## Voraussetzungen

- **Docker**: Installieren Sie Docker, um das Image zu erstellen und auszuführen.
- **Optional: Docker Hub Proxy**: Falls Sie einen Proxy verwenden, können Sie diesen als `DOCKER_HUB_PROXY` angeben.

## Build-Argumente

Beim Erstellen des Docker-Images können folgende Argumente verwendet werden:

- `DOCKER_HUB_PROXY`: Optional. Docker Hub Proxy für Netzwerkeinschränkungen.
- `CORE_TAG` und `CORE_COMMIT`: Bestimmt die Version des MISP-Codes, der aus dem GitHub-Repository heruntergeladen wird.
- `PHP_VER`: PHP-Version, die verwendet wird.
- **Pypi Module Versions**: Zusätzliche Versionen für Python-Pakete wie `redis`, `lief`, `pydeep2`, etc.

## Build-Anweisungen

Um das Docker-Image zu erstellen, führen Sie folgenden Befehl aus:

```sh
docker build -t misp-docker --build-arg CORE_TAG=<tag> --build-arg PHP_VER=<php-version> .
```

Dabei ersetzen Sie `<tag>` und `<php-version>` durch die gewünschten Werte für MISP und PHP.

## Docker Container starten

Sobald das Image erstellt ist, kann der Container gestartet werden:

```sh
docker run -p 443:443 -p 80:80 -d misp-docker
```

Dies öffnet die MISP-Anwendung auf den Ports 80 und 443 des Hosts.

## Erläuterung der Build-Stages

Dieses Dockerfile ist in mehrere Build-Stages aufgeteilt:

1. **composer-build**: Installiert PHP und dessen Abhängigkeiten sowie Composer und zusätzliche PHP-Bibliotheken, die für MISP erforderlich sind.
  
2. **php-build**: Installiert PHP-Entwicklungstools und -Erweiterungen sowie spezifische Bibliotheken für MISP.

3. **python-build**: Installiert Python und seine Abhängigkeiten. Der MISP-Code wird geklont und für die Anforderungen der Plattform vorbereitet.

4. **Endgültiges Image**: Installiert alle restlichen Abhängigkeiten, konfiguriert Nginx und Supervisor und stellt sicher, dass MISP mit den richtigen Berechtigungen und Verzeichnissen ausgestattet ist.

Zusätzlich werden Skripte für das Logging und Backup konfiguriert und notwendige Berechtigungen für die **www-data**-Nutzergruppe gesetzt, sodass MISP als Webanwendung in Docker laufen kann.

## Wichtige Verzeichnisse

- **/var/www/MISP**: Enthält den MISP-Code und Daten.
- **/var/log/supervisor**: Logs für Supervisor.
- **/etc/nginx**: Konfiguration für den Nginx-Webserver.

## Hinweise

- **Persistent Volumes**: Für die Datenbank oder wichtige Logs wird empfohlen, Volumes zu verwenden.
- **Sudoers**: Der Benutzer `www-data` hat in dieser Konfiguration bestimmte `sudo`-Berechtigungen, um MISP zu verwalten.

Weitere Informationen zur Verwendung von MISP finden Sie in der [offiziellen Dokumentation](https://github.com/MISP/MISP).