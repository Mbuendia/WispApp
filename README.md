# WispCraft

WispCraft es un addon para World of Warcraft (Midnight / Forever) que transforma el sistema de susurros nativo en una interfaz moderna al estilo de una app de mensajería (tipo WhatsApp/Telegram).

## ✨ Características Actuales (v1.4)

* 📱 **Interfaz Moderna:** Burbujas de chat, historial independiente por contacto y ordenación automática por última interacción.
* 👁️ **Modo Peek:** Minimiza la interfaz a un pequeño header de 52px que no interfiere en tu visión de juego.
* 🔴 **Notificaciones Globales:** Botón integrado en el minimapa con contador rojo de mensajes no leídos.
* ⚙️ **Panel de Configuración UI:** Interfaz visual /wc config para modificar el comportamiento sin tocar código.
* 💤 **Rastreo Auto AFK/DND:** Visualiza al instante si tus contactos están ausentes (🌙) o en no molestar (⛔).
* 🖱️ **Menú Contextual:** Haz clic derecho en un contacto de la lista para silenciarlo, borrar el historial o añadir una nota.
* 📝 **Notas de Jugador:** Escribe apuntes persistentes bajo el nombre de cada contacto (ej: "Líder de Raid" o "Vendedor de pociones").
* ⚡ **Respuestas Rápidas (Plantillas):** Escribe :: o / en el cuadro de texto para desplegar el menú de autocompletado y responder al instante.
* 🟡 **Links de Objetos:** Soporte total para enlazar objetos haciendo Shift+Clic desde tu mochila directo al chat.
* ⚔️ **Auto-Ocultar:** Opción para que el addon entre en modo Peek automáticamente al detectar el inicio de un combate.

---

## ⌨️ Guía Rápida de Uso (Comandos)

Puedes utilizar tanto /wispcraft como el atajo corto /wc:

* /wc - Alterna entre abrir, minimizar al Modo Peek y cerrar el teléfono.
* /wc config (o /wc settings) - Abre el panel central de opciones. Desde aquí gestionas el sonido, el combate y creas o borras tus plantillas rápidas.
* /wc combat on o /wc combat off - Atajo para activar/desactivar la ocultación automática en fase de combate.
* /wc reset - Formatea la base de datos local y recarga la interfaz. ¡Atención! Esto borrará tus notas y plantillas guardadas.

---

## 🗺️ Roadmap de Implementación

* ✅ **v1.0** - Versión base (diseño UI y anclajes).
* ✅ **v1.1** - Código refactorizado (6 submódulos), Modo Peek, Badge Minimapa.
* ✅ **v1.2** - Panel /wc config, Integración de estados AFK/DND de WoW.
* ✅ **v1.3** - Menú Contextual, Sistema de Silenciar (Mute), Borrar Conversación, Notas de contacto.
* ✅ **v1.4** - Plantillas (Autocomplete con ::), Renderizado de Links de Objetos (Shift+Clic).
* ✅ **v1.5** - Redimensionado fluido de la ventana principal (Drag-to-resize).
* ✅ **v1.6** - Protocolo WispCraft P2P: Animación de "escribiendo..." (•••), acuses de lectura reales (ticks azules ✓✓) y vibración/shake al recibir mensajes importantes.

