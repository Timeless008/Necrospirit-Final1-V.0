# Necro Spirit — Definitieve versie (v12 Final)

Dit is de definitieve pakketversie van de werkende Necro Spirit v12. De applicatiecode is bewust ongewijzigd gelaten ten opzichte van v12, zodat er geen nieuwe functionele wijzigingen worden geïntroduceerd.

## Inbegrepen
- Donkere horrorinterface.
- Nederlands- en Engelstalige interface/woordenlijsten.
- Spirit Box Pro en overige bestaande functies.
- Automatische woordscan via microfoonspraakherkenning.
- Tijdens de automatische woordscan ook softwarematig gegenereerde willekeurige woorden: eerste woord na ongeveer 12 seconden, daarna doorgaans elke 20–40 seconden zolang de scan actief is.
- SB70-optie verwijderd.
- GitHub Actions-workflow om een Android-debug-APK te bouwen.

## APK bouwen via GitHub
1. Pak deze ZIP uit.
2. Upload de **inhoud** van de uitgepakte map naar de hoofdmap van je GitHub-repository. `pubspec.yaml`, `lib/` en `assets/` moeten direct in de repository-root staan. Neem ook `.github/workflows/` mee.
3. Commit de bestanden naar de repository.
4. Open **Actions → Build Necro Spirit APK → Run workflow**.
5. Na een geslaagde workflow download je het artifact `necro-spirit-debug-apk`.

## Belangrijke informatie
- Dit project bevat Flutter-broncode en een GitHub Actions-workflow; de APK wordt door GitHub gebouwd.
- Deze ZIP is gecontroleerd op integriteit, maar de APK is niet opnieuw lokaal gecompileerd of getest bij het maken van dit definitieve archief.
- De automatische microfoonfunctie gebruikt de Android-spraakherkenningsdienst. Beschikbaarheid en resultaten hangen af van Android, de geselecteerde taal, microfoonrechten en de beschikbare spraakdienst.
- Willekeurige woorden zijn software-effecten. Ze zijn geen bewijs van spiritcommunicatie en de app detecteert of communiceert niet met geesten.
- Dit is een debug-APK voor persoonlijk testen, geen Play Store-release.


## Release version

This source package is set to version **1.0.0** (build number **1**) in `pubspec.yaml`. This sets the Android app version metadata when built with Flutter. It does not by itself publish the app to Google Play or make it Play Protect-verified.

The Dutch and English word banks have been expanded with additional dark, gothic, and fictional horror-themed phrases. These are generated app prompts, not evidence of paranormal activity.
