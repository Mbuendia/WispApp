# libs/

Esta carpeta es para librerías externas de WoW addon development.

## Librerías recomendadas para WispChat v2+

| Librería | URL | Uso |
|---|---|---|
| **LibStub** | https://www.curseforge.com/wow/addons/libstub | Base para registrar librerías |
| **AceDB-3.0** | https://www.wowace.com/projects/ace3 | SavedVariables avanzado con perfiles por personaje |
| **LibDBIcon-1.0** | https://www.curseforge.com/wow/addons/libdbicon-1-0 | Botón de minimapa profesional (reemplaza el actual) |
| **AceLocale-3.0** | https://www.wowace.com/projects/ace3 | Localización (ES, EN, DE, FR...) |

## Cómo añadir una librería

1. Descarga la librería y coloca su carpeta aquí: `libs/NombreLib/`
2. Añade su archivo `.lua` en `WispChat.toc` ANTES de `WispChat.lua`:

```toc
## Interface: 120100
## Title: WispChat
## SavedVariables: WispChatDB

libs/LibStub/LibStub.lua
libs/AceDB-3.0/AceDB-3.0.lua
WispChat.lua
```
