# WispCraft

<div align="center">
  <img src="https://raw.githubusercontent.com/Mbuendia/WispApp/main/wispcraft_demo.gif" alt="WispCraft Animado" width="600" />
  <br/>
  <p><em>Revoluciona tus susurros de World of Warcraft con una interfaz moderna, temas de faccion dinamicos y GPS integrado.</em></p>
</div>

WispCraft es un addon para World of Warcraft (Midnight / Forever) que transforma el sistema de susurros nativo en una interfaz moderna y flotante al estilo de una app de mensajeria (tipo WhatsApp o Telegram).

## 🌟 Features Principales (v2.0)

* 📱 **Interfaz Moderna y Movil:** Burbujas de chat, panel lateral con tu historial de contactos ordenado por actividad reciente y barra superior arrastrable (Drag-to-move).
* 🎨 **Tematizacion Dinamica (NUEVO):** La interfaz detecta tu faccion automaticamente y adapta todos sus colores. Rojo y grises oscuros para la Horda, Azul rey y dorado para la Alianza, garantizando siempre el maximo contraste.
* 💬 **Protocolo P2P (WispCraft-to-WispCraft):** Si ambos jugadores teneis el addon, disfrutareis de funciones premium:
  * Indicador de 'escribiendo...' en tiempo real.
  * Acuses de lectura (ticks verdes vv al enviar, ticks azules vv al ser leidos).
  * Animaciones fluidas al recibir mensajes nuevos.
* 🗺️ **Integracion TomTom y WoWHead (NUEVO):** Pulsa el nuevo boton de mapa (📍) para compartir tus coordenadas exactas. Los enlaces de WoWHead abriran una ventana para copiar, y las coordenadas se enviaran directo a tu addon TomTom con solo un clic.
* 🙈 **Modo Peek y Auto-Combate:** Oculta el addon dejandolo en una minuscula barra verde para no molestar. Puedes configurarlo para que se oculte automaticamente al entrar en combate.
* ⚙️ **Panel de Configuracion:** Interfaz visual /wc config, ahora semitransparente, para modificar todos los ajustes, sonidos y plantillas de respuesta sin tocar codigo.
* 📝 **Menu Contextual y Notas:** Haz clic derecho en la barra lateral para silenciar, borrar o anadir notas doradas a tus contactos (ej: 'Tanque de la Raid').
* ⚡ **Respuestas Rapidas (Plantillas):** Escribe :: en el chat para abrir un menu de autocompletado y mandar textos predefinidos al instante.

---

## ⌨️ Comandos y Guia de Uso

Puedes utilizar tanto /wispcraft como el atajo corto /wc:

* /wc - Alterna entre abrir, minimizar al Modo Peek y cerrar la interfaz por completo.
* /wc config (o /wc settings) - Abre el panel central de opciones.
* /wc combat on o /wc combat off - Atajo rapido para activar/desactivar la ocultacion automatica en combate.
* /wc reset - Formatea la base de datos local y recarga la interfaz. ¡Atencion! Esto borrara notas y plantillas.

---

## 📸 Como añadir el GIF a este README

Para que el GIF superior funcione:
1. Graba un clip de 5-10 segundos en el juego (usando OBS, Gyazo, ShareX, o Xbox Game Bar) ensenando como cambian los colores, como se mueve la ventana y las nuevas animaciones.
2. Guarda el video como **wispcraft_demo.gif**.
3. Sube ese archivo directamente a la raiz de este repositorio de GitHub. 
¡La imagen de arriba empezara a funcionar magicamente!

---

## 🗺️ Roadmap Completado

* ✅ **v1.0** - Version base y maquetacion visual.
* ✅ **v1.1** - Modularizacion (Core, UI, Events), Modo Peek y Mini-mapa.
* ✅ **v1.2** - Menu de Opciones /wc config y estados AFK/DND.
* ✅ **v1.3** - Menu Contextual (Silenciar, Borrar, Notas).
* ✅ **v1.4** - Autocompletado (Plantillas) y Enlaces de Objetos.
* ✅ **v1.5** - Ventana arrastrable y compatibilidad.
* ✅ **v1.6** - Protocolo P2P (Ticks azules, escribiendo..., y sonidos UI).
* ✅ **v2.0** - Interfaz de Faccion, Texturas Nativas, Integracion WoWHead/TomTom y Animaciones.