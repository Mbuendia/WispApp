# Changelog — WispChat

All notable changes to this project will be documented here.
Format: [Semantic Versioning](https://semver.org/)

---

## [Unreleased]

### Planned
- Historial persistente entre sesiones (SavedVariables)
- Modo claro (WhatsApp Light theme)
- Emojis auto-conversión `:)` → 😊
- Foto de perfil basada en clase WoW

---

## [1.0.0] — 2026-09-18

### Added
- 📱 Interfaz tipo teléfono arrastrable sobre la pantalla del juego
- 💬 Panel de chat con burbujas estilo WhatsApp Dark
  - Burbujas entrantes: teal oscuro, alineadas a la izquierda
  - Burbujas salientes: verde WA, alineadas a la derecha
  - Doble tick ✓✓ verde en mensajes enviados
  - Timestamps por mensaje (HH:MM)
- 👤 Sidebar de contactos
  - Avatar con inicial del nombre (color determinista)
  - Preview del último mensaje
  - Badge verde con contador de no leídos
  - Ordenación por actividad más reciente
- ⌚ Barra de estado simulada (hora del sistema, iconos WiFi/batería)
- 🔔 Sonido de notificación al recibir susurros
- 🔄 Auto-apertura al recibir el primer susurro de sesión
- ✏️ Campo de texto con placeholder y botón enviar
- 🖱️ Botón 💬 en el minimapa para abrir/cerrar
- 💾 Persistencia de posición entre sesiones via SavedVariables
- 🔧 Slash commands: `/wispchat`, `/wc`, `/wc reset`
- 🔁 Captura susurros enviados desde el chat nativo (CHAT_MSG_WHISPER_INFORM)
- 🛡️ 100% compatible con Midnight API restrictions (sin datos de combate)

### Technical
- Dedup de mensajes salientes via `pendingOut` map para evitar duplicados
  entre push optimista y evento `CHAT_MSG_WHISPER_INFORM`
- Medición de texto con FontString oculto antes de crear burbujas (layout preciso)
- Namespace privado `local ADDON_NAME, ns = ...` — sin contaminación global
- Target: WoW 12.1.0 · Interface 120100 · Build 69814
