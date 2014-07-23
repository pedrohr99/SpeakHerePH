SpeakHerePH
===========

**Actualización a iOS 7 del ejemplo SpeakHear usando AVAudioSession**

Este proyecto es una actualización del ejempo SpeakHere creado por Apple para dispositivos iOS. Exactametne la versión 2.5 (2012-09-10) en [developer.apple.com](https://developer.apple.com/library/ios/samplecode/SpeakHere/Introduction/Intro.html "SpeakHere Apple project")

El proyecto realizado por Apple en 2012 usa Audio Session, sin embargo Audio Session es considerado obsoleto en iOS 7. Por esa razón, he actualizado este proyecto con  AVAudioSession para iOS 7.0 SDK, de esta forma he eliminado estos avisos de codigo obsoleto.

*Para un mayor detalle, he modificado las siguientes clases:*

**SpeakHereController.m**

En resumen en el metodo play he asignado la categoría para playback y de igual forma he aplicado la categoría para la grabación en el método record. También he actualizado AVAudioSession en los métodos awakeFromNib y enterForeground. El código obsoleto está comentado, por si quieres verlo. En el commit "Updated to iOS 7 with AVAudioSession" puedes ver los cambios que he hecho.

**AQRecorder.mm**

Después que he comentado el código obsoleto he adquirido la frecuencia de muestreo y el número de canales usando AVAudioSession en el método SetupAudioFormat. En el commit "Updated to iOS 7 with AVAudioSession" puedes ver la porción de código modificada.

***

ADVERTENCIA: Este ejemplo sólo funciona en iOS 7.0. No funciona en iOS 7.1 y posteriores. Este es sólo un ejemplo sencillo que hice cuando iOS 7.0 fue lanzado.

***

* twitter: [@pedrohr99](https://twitter.com/pedrohr99 "twitter @pedrohr99")
* linkedIn: [pedrohr99](http://www.linkedin.com/in/pedrohr99 "linkedIn pedroh")