# Windows Security Baseline Audit

## Descripción

Este proyecto contiene un script de PowerShell para realizar una revisión básica de seguridad en un equipo Windows.

La herramienta recopila algunos indicadores que pueden ser útiles durante una revisión inicial de postura de seguridad, sin realizar cambios en la configuración del sistema.

## Objetivo

El objetivo es obtener una visión rápida de algunos controles de seguridad del equipo y presentar los resultados de una forma sencilla.

Las comprobaciones incluidas son:

- Información del sistema operativo.
- Estado de Microsoft Defender, cuando está disponible.
- Estado de los perfiles de Windows Firewall.
- Configuración de Remote Desktop (RDP).
- Estado de SMBv1, cuando la característica está disponible.
- Integrantes del grupo local `Administrators`.

## Tecnologías

- PowerShell 5.1 o superior
- Windows 10/11 o Windows Server con los cmdlets disponibles

## Archivos

```text
powershell-security-scripts/
├── Invoke-SecurityBaselineAudit.ps1
├── example-output.txt
└── README.md
```

## Uso

1. Descargar o clonar el repositorio.
2. Abrir PowerShell.
3. Ir a la carpeta del proyecto.
4. Ejecutar:

```powershell
.\Invoke-SecurityBaselineAudit.ps1
```

Para guardar el resultado en formato JSON:

```powershell
.\Invoke-SecurityBaselineAudit.ps1 -OutputPath .\reports\security-audit.json
```

## Ejemplo de resultado

El script muestra una tabla similar a:

```text
Windows Security Baseline Audit
Generated: 2026-09-28 12:00:00
Computer : DESKTOP-EXAMPLE

Check                         Status   Details
-----                         ------   -------
Operating System              INFO     Microsoft Windows 11...
Microsoft Defender            PASS     AntivirusEnabled=True...
Windows Firewall - Domain     PASS     Enabled=True
Windows Firewall - Private    PASS     Enabled=True
Windows Firewall - Public    PASS     Enabled=True
Remote Desktop                PASS     Remote Desktop is disabled.
SMBv1                         PASS     State=Disabled
Local Administrators          INFO     COMPUTER\User
```

Los resultados dependen de la configuración del equipo donde se ejecute.

## Consideraciones

Este proyecto está pensado como una herramienta de revisión inicial. Un resultado `PASS` no significa que el equipo esté completamente seguro y un resultado `REVIEW` indica que conviene revisar la configuración con mayor detalle.

El script es de solo lectura y no modifica las configuraciones evaluadas.

## Aprendizaje

El proyecto sirve como práctica de PowerShell aplicada a seguridad informática. También permite relacionar la automatización con tareas de revisión y levantamiento de información de seguridad.

