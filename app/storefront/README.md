# Storefront stand-in

This is not the Feldmarkt shop. The shop is the Spring Boot **JAR** (**Java Archive**) already running on the colo virtual machine. This module builds an image with the same contract so the pipeline has something to pin:

- Java 21
- Spring Boot **3.5.5**, the version recorded as `appVersion` in the chart and as `springBootVersion` in the env files
- `GET /health` on port 8080 returns 200 only when `SELECT 1` succeeds

The migration does not upgrade that version. If the colo inventory names a different Spring Boot version, change the parent version here, `charts/storefront/Chart.yaml`, and the three env files together.
