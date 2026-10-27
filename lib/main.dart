import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const SpiritApp());

const violet = Color(0xFF8B0000);
const horrorCrimson = Color(0xFFB00020);
const bg = Color(0xFF020102);

class SpiritApp extends StatelessWidget {
  const SpiritApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Necro Spirit', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: horrorCrimson, brightness: Brightness.dark).copyWith(secondary: violet, primary: horrorCrimson),
      scaffoldBackgroundColor: bg, appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF080204))),
    home: const HomePage());
}

class _EnergyOrb extends StatefulWidget { const _EnergyOrb(); @override State<_EnergyOrb> createState() => _EnergyOrbState(); }
class _EnergyOrbState extends State<_EnergyOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _controller, builder: (context, _) {
    final glow = 12.0 + _controller.value * 18.0;
    return Container(width:94, height:78, alignment:Alignment.center, decoration:BoxDecoration(shape:BoxShape.circle, gradient:RadialGradient(colors:[const Color(0xFF8B0000).withOpacity(0.30 + _controller.value*0.22), const Color(0xFF160004).withOpacity(0.10), Colors.transparent]), boxShadow:[BoxShadow(color:const Color(0xFF8B0000).withOpacity(0.38), blurRadius:glow, spreadRadius:2)]), child:Icon(Icons.graphic_eq, size:56, color:Color.lerp(const Color(0xFF8B0000), const Color(0xFFFF3B3B), _controller.value*0.4)));
  });
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState() => _HomePageState(); }

class _HomePageState extends State<HomePage> {
  final _question = TextEditingController();
  final _tts = FlutterTts();
  final _speech = stt.SpeechToText();
  final AudioRecorder _evpRecorder = AudioRecorder();
  final AudioPlayer _evpPlayer = AudioPlayer();
  final TextEditingController _evpQuestion = TextEditingController();
  final List<Map<String,dynamic>> _evpClips = [];
  Timer? _evpTimer;
  int _evpSecondsLeft = 15;
  int _evpSelectedDuration = 15;
  DateTime? _evpStartedAt;
  bool _evpRecording = false, _evpPlaying = false;
  String? _evpCurrentPath;
  Duration _evpDuration = Duration.zero, _evpPosition = Duration.zero;
  final _rng = Random();
  // Keep recent generated words so the Spirit Box does not repeat the last two.
  final List<String> _recentGeneratedWords = [];
  // Dark horror-themed word bank. These are software-generated prompts, not spirit evidence.
  final List<String> _wordsNl = [
    'De duivel','Demon','Duivel','Satan','Lucifer','Hel','Vagevuur','Vloek','Spreuk','Ritueel','Bezeten','Bezetenheid','Oproepen','Verboden','Offer','Bloed','As','Graf','Kist','Lijk','Dood','Sterven','Sterf','Verdwijn','Schaduw','Duisternis','Nacht','Middernacht','Kerkhof','Begraafplaats','Grafsteen','Geest','Verschijning','Dwaallicht','Kwaad','Boosaardig','Dreiging','Angst','Schrik','Pijn','Lijden','Wraak','Haat','Leugen','Verraad','Geheim','Verborgen','Verdoemd','Verdoemenis','Vernietiging','Verloren','Gevangen','Ketenen','Ketting','Kloppen','Fluisteren','Kreunen','Schreeuw','Huilen','Kras','Krasgeluid','Voetstappen','Achter je','Naast je','Onder je','Boven je','Achterdeur','Kelder','Zolder','Kamer','Gang','Spiegel','Venster','Deur','Slot','Sleutel','Open','Niet openen','Niet kijken','Kijk niet','Draai je om','Ga weg','Blijf','Blijf hier','Kom dichterbij','Kom alleen','Ik wacht','Ik zie je','Ik ken je','Ik ben hier','Ik ben dichtbij','Je bent alleen','Je hoort mij','Je riep mij','Jij riep','Je hebt mij geroepen','Laat mij binnen','Laat mij los','Laat me gaan','Ik kom terug','Het is begonnen','Het ritueel begint','De poort','De poort is open','Sluit de poort','Breek de cirkel','Zeg de spreuk','Zwijg','Stilte','Geen licht','Doof het licht','Rood licht','Zwarte kaars','Zwarte magie','Pentagram','Sigil','Runen','Oud bloed','Offerande','Altaar','Tempel','Verbond','Pact','Ziel','Je ziel','Neem je ziel','Verkoop je ziel','Eeuwig','Voor altijd','Geen ontsnapping','Geen uitweg','Te laat','Je bent te laat','Vlucht','Verstop je','Verberg je','Ik vind je','Ik volg je','Ik volg','Ik ben achter je','Niet alleen','Er zijn meer','Wij zijn velen','Ze komen','Ze kijken','Ze luisteren','Iets beweegt','Het ademt','Koude adem','Koude plek','Koude handen','Zwarte ogen','Rode ogen','Lege ogen','Geen gezicht','Vervormd','Verrot','Rot','Schimmel','Maden','Raven','Kraaien','Vleermuis','Wolf','Klauw','Tanden','Nagels','Krassen','Bloedspoor','Bloed op de muur','Handafdruk','Kinderstem','Fluisterstem','Stem uit de muur','Stem in de kelder','Hoor je dat','Wat heb je gedaan','Waarom ben je hier','Wie heeft je gestuurd','Noem mijn naam','Spreek mijn naam','Vergeet mijn naam','Zeg ja','Zeg nee','Niet antwoorden','Vergeet mij niet','Herinner je mij','Ik herinner me','Ik was hier','Ik ben niet weg','Ik slaap niet','Ik rust niet','Geen vrede','Geen vergeving','Geen redding','Geen genade','Oordeel','Schuld','Berouw','Zonde','Zondaar','Heiligschennis','Profanatie','Vervloekt','Vervloeking','Duistere kracht','Onheil','Omen','Voorteken','Noodlot','Einde','Het einde','Laatste adem','Laatste uur','Laatste waarschuwing','Waarschuwing','Pas op','Gevaar','Dodelijk','Verstikking','Adem niet','Luister goed','Hoor mij','Antwoord mij','Wie ben jij','Wat ben jij','Waarom fluister je','Waar ben je','Ik weet het','Ik weet waar je bent','Ik kom voor jou','Jij bent van mij','Vanavond','Deze nacht','Morgen niet','Nooit meer','Slaap niet','Word wakker','Word wakker nu','Wakker','Slaap','Nachtmerrie','Droom van mij','Ik zit in je droom','De muur bloedt','De vloer beweegt','De deur kraakt','De bel luidt','Drie kloppen','Drie keer','Zeven','Dertien','666','Oude naam','Oude god','Vergeten god','Demonische stem','Onzichtbaar','Onbekend','Onmenselijk','Bovennatuurlijk','Duivels','Demonisch','Occult','Zwarte sluier','Rituele cirkel','Laatste zegel','Verbroken zegel','Het zegel breekt','De cirkel sluit','De cirkel is gebroken','Niet veilig','Nergens veilig','Je bent niet veilig',
    'Kerkklok','Doodsengel','Poortwachter','Onderwereld','Afgrond','Schimmenrijk','Vloekschrift','Zwarte mis','Duistere eed','Bloedmaan','Bloedrode maan','Eclips','Totem','Dodenritueel','Bezieling','Dodenwake','Grafkelder','Catacombe','Mausoleum','Sarcofaag','Doodskist','Lijkwade','Skelet','Schedel','Beenderen','Doodsadem','Doodsstilte','Koude rilling','Koude vingers','Onheilspellend','Verdoemenis wacht','De doden horen je','De doden spreken','De stilte antwoordt','Iemand staat daar','Niet achterom kijken','Blijf uit de kelder','De trap kraakt','De vloer is koud','De lucht wordt zwaar','De kaars dooft','De vlam beweegt','De schaduw lacht','Een stem roept','Een naam klinkt','Ik ken je geheim','Je bent geroepen','De nacht kiest jou','Het huis onthoudt','De muren luisteren','De ramen huilen','De klok staat stil','De tijd is weg','De cirkel is gesloten','Het zegel is verbroken','De poort ademt','De poort roept','De afgrond kijkt','De schaduw wacht','De schaduw beweegt','De laatste getuige','De laatste ziel','De verloren ziel','Rusteloos','Onrustige geest','Wraakzuchtige geest','Dwaalgeest','Schim','Spookverschijning','Nachtwezen','Schaduwwezen','Duistere aanwezigheid','Onbekende aanwezigheid','Verborgen aanwezigheid','Oude vloek','Eeuwige vloek','Vergeten ritueel','Verboden naam','Heilige grond','Ontheiligd','Zwarte rook','Grijze mist','Dichte mist','Koude mist','Rook in de gang','Voetstap boven','Voetstap beneden','Klop op de deur','Klop van binnen','Drie schaduwen','Zes kaarsen','Dertien treden','Zwarte spiegel','Gebroken spiegel','Blinde hoek','Verzegelde kamer','Verlaten kapel','Vergeten altaar','Donkere kapel','Onder het huis','Achter de muur','In de schaduw','In de spiegel','In het donker','Niet alleen vannacht','Je hoort de bel','Je naam wordt genoemd','Ik fluister jouw naam','Ik wacht beneden','Ik sta achter de deur','Ik ben niet menselijk','Ik ben niet alleen','Laat het licht branden','Doe de deur dicht','Open het raam','Verbreek het pact','Betaal de schuld','De prijs is bloed','Je hebt iets gewekt','Je hebt iets gezien','Het komt dichterbij','Het kijkt naar jou','Het kent je naam','Het wil naar binnen','Het is te laat','Er is geen uitweg','Je kunt niet vluchten','De nacht eindigt niet','De stilte liegt','De stem liegt','De waarheid slaapt','De waarheid bloedt','Schuld betaalt zich terug','Angst voedt het','Noem drie namen','Zeg de woorden','Vergeet de regels','Breek de stilte','Luister naar de muur','Volg de voetstappen','Keer niet terug','Blijf wakker','Slaap zacht','Tot de dageraad','Voor zonsopgang','Bij het laatste uur','Onder de zwarte maan','Waar licht sterft','Waar schaduwen wonen','Uit de diepte','Van gene zijde','Tussen twee werelden','Achter het gordijn','De andere kant','De grens vervaagt','De sluier scheurt','De sluier is dun','De doden wachten','De poort blijft open','Het huis is wakker','De kelder leeft','De zolder roept','De kamer ademt','De gang wordt langer','De deur verdwijnt','De sleutel draait','Het slot springt open','De ketting breekt','De ketenen rammelen','Een koude hand','Een bleke hand','Zwarte veren','As op de vloer','Bloed op het glas','Krassen van binnen','Een kind lacht','Een stem zonder mond','Een gezicht in glas','Ogen in het donker','Iemand fluistert','Iemand huilt','Iemand klopt','Iemand kijkt','Niemand is veilig','Niemand antwoordt','Geen rust hier','Geen licht hier','Geen naam','Geen gezicht','Geen adem','Geen hartslag','Stilte nu','Kom terug','Ga niet weg','Blijf bij mij','Verlaat mij','Vergeef mij','Ik ben verloren','Ik ben vergeten','Ik ben gebonden','Ik ben opgesloten','Bevrijd mij','Verbreek mijn ketens','Geef mij rust','Geef mij een naam','Herinner mijn stem','Hoor mijn laatste woord'
  ];
  final List<String> _wordsEn = [
    'The Devil','Demon','Devil','Satan','Lucifer','Hell','Purgatory','Curse','Spell','Ritual','Possessed','Possession','Summon','Forbidden','Sacrifice','Blood','Ashes','Grave','Coffin','Corpse','Death','Die','Dying','Disappear','Shadow','Darkness','Night','Midnight','Graveyard','Cemetery','Tombstone','Ghost','Apparition','Wisp','Evil','Malice','Threat','Fear','Terror','Pain','Suffering','Revenge','Hate','Lie','Betrayal','Secret','Hidden','Doomed','Damnation','Destruction','Lost','Trapped','Chains','Chain','Knocking','Whispering','Groaning','Scream','Crying','Scratching','Footsteps','Behind you','Beside you','Below you','Above you','Back door','Basement','Attic','Room','Hallway','Mirror','Window','Door','Lock','Key','Open','Do not open','Do not look','Don’t look','Turn around','Go away','Stay','Stay here','Come closer','Come alone','I am waiting','I see you','I know you','I am here','I am near','You are alone','You hear me','You called me','You summoned me','Let me in','Let me go','Release me','I will return','It has begun','The ritual begins','The gate','The gate is open','Close the gate','Break the circle','Speak the spell','Silence','No light','Put out the light','Red light','Black candle','Black magic','Pentagram','Sigil','Runes','Old blood','Offering','Altar','Temple','Pact','Soul','Your soul','Take your soul','Sell your soul','Forever','Eternity','No escape','No way out','Too late','You are too late','Run','Hide','Hide yourself','I will find you','I am following you','I follow','I am behind you','Not alone','There are more','We are many','They are coming','They are watching','They are listening','Something moves','It is breathing','Cold breath','Cold spot','Cold hands','Black eyes','Red eyes','Empty eyes','No face','Twisted','Rotten','Rot','Mold','Maggots','Ravens','Crows','Bat','Wolf','Claw','Teeth','Nails','Scratches','Blood trail','Blood on the wall','Handprint','Child’s voice','Whispering voice','Voice in the wall','Voice in the basement','Did you hear that','What have you done','Why are you here','Who sent you','Say my name','Speak my name','Forget my name','Say yes','Say no','Do not answer','Do not forget me','Do you remember me','I remember','I was here','I am not gone','I do not sleep','No rest','No peace','No forgiveness','No salvation','No mercy','Judgment','Guilt','Remorse','Sin','Sinner','Blasphemy','Profanation','Cursed','Damnation','Dark force','Omen','Sign','Fate','End','The end','Last breath','Final hour','Final warning','Warning','Beware','Danger','Deadly','Suffocation','Do not breathe','Listen carefully','Hear me','Answer me','Who are you','What are you','Why are you whispering','Where are you','I know','I know where you are','I am coming for you','You belong to me','Tonight','This night','Not tomorrow','Never again','Do not sleep','Wake up','Wake up now','Awake','Sleep','Nightmare','Dream of me','I am in your dream','The wall is bleeding','The floor is moving','The door is creaking','The bell is ringing','Three knocks','Three times','Seven','Thirteen','666','Old name','Old god','Forgotten god','Demonic voice','Invisible','Unknown','Inhuman','Supernatural','Devilish','Demonic','Occult','Black veil','Ritual circle','Final seal','Broken seal','The seal is breaking','The circle closes','The circle is broken','Not safe','Nowhere is safe','You are not safe',
    'Church bell','Angel of death','Gatekeeper','Underworld','Abyss','Realm of shadows','Book of curses','Black mass','Dark oath','Blood moon','Red moon','Eclipse','Totem','Death ritual','Possession','Vigil for the dead','Crypt','Catacomb','Mausoleum','Sarcophagus','Death shroud','Skeleton','Skull','Bones','Death breath','Deathly silence','Cold shiver','Cold fingers','Ominous','Damnation awaits','The dead hear you','The dead are speaking','Silence answers','Someone is there','Do not look back','Stay out of the basement','The stairs creak','The floor is cold','The air grows heavy','The candle dies','The flame moves','The shadow smiles','A voice calls','A name is spoken','I know your secret','You have been summoned','The night chooses you','The house remembers','The walls are listening','The windows are crying','The clock has stopped','Time is gone','The circle is sealed','The seal is broken','The gate is breathing','The gate is calling','The abyss is watching','The shadow waits','The shadow moves','The last witness','The last soul','The lost soul','Restless','Restless spirit','Vengeful spirit','Wandering spirit','Wraith','Apparition','Night creature','Shadow creature','Dark presence','Unknown presence','Hidden presence','Ancient curse','Eternal curse','Forgotten ritual','Forbidden name','Hallowed ground','Desecrated','Black smoke','Grey mist','Thick fog','Cold mist','Smoke in the hallway','Footsteps above','Footsteps below','Knock at the door','Knocking from inside','Three shadows','Six candles','Thirteen steps','Black mirror','Broken mirror','Blind corner','Sealed room','Abandoned chapel','Forgotten altar','Dark chapel','Beneath the house','Behind the wall','In the shadows','In the mirror','In the darkness','Not alone tonight','You hear the bell','Your name is spoken','I whisper your name','I wait below','I stand behind the door','I am not human','I am not alone','Keep the light on','Close the door','Open the window','Break the pact','Pay the debt','The price is blood','You awakened something','You have seen something','It is getting closer','It is watching you','It knows your name','It wants to come in','It is too late','There is no way out','You cannot escape','The night never ends','Silence lies','The voice lies','Truth is sleeping','Truth is bleeding','Guilt comes due','Fear feeds it','Name three names','Speak the words','Forget the rules','Break the silence','Listen to the wall','Follow the footsteps','Do not return','Stay awake','Sleep well','Until dawn','Before sunrise','At the final hour','Beneath the black moon','Where light dies','Where shadows dwell','From the depths','From the other side','Between two worlds','Behind the veil','The other side','The boundary fades','The veil tears','The veil is thin','The dead are waiting','The gate stays open','The house is awake','The basement lives','The attic calls','The room is breathing','The hallway grows longer','The door disappears','The key turns','The lock clicks open','The chain breaks','The shackles rattle','A cold hand','A pale hand','Black feathers','Ashes on the floor','Blood on the glass','Scratches from within','A child laughs','A voice without a mouth','A face in the glass','Eyes in the dark','Someone whispers','Someone cries','Someone knocks','Someone is watching','No one is safe','No one answers','No rest here','No light here','No name','No face','No breath','No heartbeat','Silence now','Come back','Do not leave','Stay with me','Abandon me','Forgive me','I am lost','I am forgotten','I am bound','I am trapped','Set me free','Break my chains','Give me rest','Give me a name','Remember my voice','Hear my final words'
  ];
  final List<Map<String, dynamic>> _history = [];
  String _answer = 'Ask a question or start a Spirit Box session.';
  String _voice = 'Female';
  String _mode = 'Vraag';
  String _language = 'English';
  String _sessionName = 'Sessie';
  double _rate = 0.45;
  bool _busy = false, _listening = false, _multiVoice = false, _pro = true;
  bool _imageBusy = false;
  bool _autoScan = false;
  Timer? _wordScanTimer;
  bool _sensorActive = false;
  StreamSubscription<MagnetometerEvent>? _magSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double? _magneticMicrotesla;
  double? _motionMagnitude;
  String _sensorStatus = 'Not started';
  DateTime _lastMatchedWord = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastMatchedText = '';
  String _lastSpokenText = '';
  DateTime _lastSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);
  Uint8List? _answerImage;
  String? _imageError;
  static const String backendUrl = String.fromEnvironment('SPIRIT_API_URL', defaultValue: '');

  @override void initState() {
    _evpPlayer.onDurationChanged.listen((d) { if (mounted) setState(() => _evpDuration = d); });
    _evpPlayer.onPositionChanged.listen((d) { if (mounted) setState(() => _evpPosition = d); });
    _evpPlayer.onPlayerComplete.listen((_) { if (mounted) setState(() => _evpPlaying = false); });

    super.initState();
    _loadHistory();
    _loadLanguage();
    _loadEvpClips();
    // Ask for microphone permission after the first screen frame, so Android
    // can show its native runtime permission dialog as soon as the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestStartupMicrophonePermission());
  }

  Future<void> _requestStartupMicrophonePermission() async {
    try {
      final status = await perm.Permission.microphone.status;
      if (status.isGranted) {
        await _prepareSpeechRecognition();
        return;
      }
      if (status.isPermanentlyDenied || status.isRestricted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_language == 'English'
              ? 'Microphone access is blocked. Open Android Settings > Apps > Necro Spirit > Permissions to allow it.'
              : 'Microfoontoegang is geblokkeerd. Open Android-instellingen > Apps > Necro Spirit > Machtigingen om dit toe te staan.'),
          action: SnackBarAction(
            label: _language == 'English' ? 'Settings' : 'Instellingen',
            onPressed: () { perm.openAppSettings(); },
          ),
          duration: const Duration(seconds: 8),
        ));
        return;
      }
      final result = await perm.Permission.microphone.request();
      if (result.isGranted) {
        await _prepareSpeechRecognition();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_language == 'English'
              ? 'Microphone permission was not granted. Voice input and automatic word scanning will not work until you allow it.'
              : 'Microfoontoestemming is niet gegeven. Spraakinvoer en automatische woordscan werken pas nadat je toestemming geeft.'),
          action: result.isPermanentlyDenied
              ? SnackBarAction(label: _language == 'English' ? 'Settings' : 'Instellingen', onPressed: () { perm.openAppSettings(); })
              : null,
          duration: const Duration(seconds: 7),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_language == 'English'
              ? 'Could not request microphone access. Check Android app permissions.'
              : 'Microfoontoestemming kon niet worden aangevraagd. Controleer de Android-appmachtigingen.'),
        ));
      }
    }
  }

  Future<void> _prepareSpeechRecognition() async {
    try {
      await _speech.initialize(
        onStatus: (_) {},
        onError: (_) {},
      );
    } catch (_) {
      // Permission can be granted even if the device speech service is missing.
      // The Speak button will show a separate diagnostic when it is used.
    }
  }

  Future<void> _startSensors() async {
    await _magSubscription?.cancel();
    await _accelSubscription?.cancel();
    try {
      _magSubscription = magnetometerEventStream().listen((e) {
        final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (mounted) setState(() { _magneticMicrotesla = magnitude; _sensorActive = true; _sensorStatus = 'Magnetometer and accelerometer active'; });
      }, onError: (_) { if (mounted) setState(() => _sensorStatus = 'Magnetometer unavailable on this device'); });
      _accelSubscription = accelerometerEventStream().listen((e) {
        final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (mounted) setState(() => _motionMagnitude = magnitude);
      }, onError: (_) { if (mounted) setState(() => _sensorStatus = 'Accelerometer unavailable on this device'); });
      if (mounted) setState(() { _sensorActive = true; _sensorStatus = 'Reading available motion and magnetic sensors'; });
    } catch (_) { if (mounted) setState(() { _sensorActive = false; _sensorStatus = 'Some sensors are unavailable'; }); }
  }

  Future<void> _toggleAutoScan() async {
    if (_autoScan) {
      _wordScanTimer?.cancel();
      _wordScanTimer = null;
      await _speech.stop();
      if (mounted) setState(() { _autoScan = false; _listening = false; });
      return;
    }
    final mic = await perm.Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_language == 'English' ? 'Microphone permission is required for word scanning.' : 'Microfoontoestemming is nodig om woorden te scannen.')));
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted && _autoScan) {
            _wordScanTimer?.cancel();
            _wordScanTimer = null;
            setState(() { _autoScan = false; _listening = false; });
          }
        },
        onError: (error) {
          _wordScanTimer?.cancel();
          _wordScanTimer = null;
          if (mounted) { setState(() { _autoScan = false; _listening = false; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((_language == 'English' ? 'Speech scan stopped: ' : 'Spraakscan gestopt: ') + error.errorMsg))); }
        },
      );
      if (!available) throw Exception('Speech recognition unavailable');
      await _startSensors();
      final locales = await _speech.locales();
      final prefix = _language == 'English' ? 'en' : 'nl';
      String? locale;
      for (final item in locales) { if (item.localeId.toLowerCase().startsWith(prefix)) { locale = item.localeId; break; } }
      locale ??= (await _speech.systemLocale())?.localeId;
      if (mounted) setState(() { _autoScan = true; _listening = true; _sensorStatus = _language == 'English' ? 'Listening for speech; occasional words are software-generated prompts' : 'Luistert naar spraak; af en toe worden softwarematig woorden gekozen'; });
      _scheduleRandomScanWord(const Duration(seconds: 12));
      await _speech.listen(
        localeId: locale, listenFor: const Duration(seconds: 60), pauseFor: const Duration(seconds: 5), partialResults: true, cancelOnError: false,
        onResult: (result) {
          if (!mounted || !_autoScan) return;
          final transcript = result.recognizedWords.toLowerCase().trim();
          final words = _language == 'English' ? _wordsEn : _wordsNl;
          String? match;
          for (final word in words) { if (transcript.contains(word.toLowerCase())) { match = word; break; } }
          if (match != null && !(match.toLowerCase() == _lastMatchedText.toLowerCase() && DateTime.now().difference(_lastMatchedWord).inSeconds < 20) && DateTime.now().difference(_lastMatchedWord).inSeconds >= 2) {
            _lastMatchedWord = DateTime.now();
            _lastMatchedText = match;
            _showResult(match, kind: _language == 'English' ? 'Microphone word match' : 'Microfoon-woordmatch');
            _speak(match);
          }
        },
      );
    } catch (e) {
      _wordScanTimer?.cancel();
      _wordScanTimer = null;
      if (mounted) { setState(() { _autoScan = false; _listening = false; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_language == 'English' ? 'Could not start scanning. Check microphone permission and Google speech services.' : 'Scannen kon niet starten. Controleer microfoonrechten en Google-spraakdiensten.'))); }
    }
  }

  void _scheduleRandomScanWord(Duration delay) {
    _wordScanTimer?.cancel();
    if (!_autoScan) return;
    _wordScanTimer = Timer(delay, () {
      if (!mounted || !_autoScan) return;
      final words = _language == 'English' ? _wordsEn : _wordsNl;
      final word = _pickFreshWord(words);
      _showResult(word, kind: _language == 'English' ? 'Random software-generated word' : 'Willekeurig softwarematig gegenereerd woord');
      _speak(word);
      // After the first word, choose a fresh interval between 20 and 40 seconds.
      _scheduleRandomScanWord(Duration(seconds: 20 + _rng.nextInt(21)));
    });
  }
  Future<void> _loadLanguage() async { final p = await SharedPreferences.getInstance(); final saved = p.getString('necro_spirit_language'); if (saved != null && mounted) setState(() { _language = saved; _answer = saved == 'English' ? 'Ask a question or start a Spirit Box session.' : 'Stel een vraag of start een Spirit Box-sessie.'; }); }
  Future<void> _setLanguage(String value) async { setState(() { _language = value; _voice = value == 'English' ? 'Female' : 'Vrouwelijk (indien beschikbaar)'; if (_history.isEmpty) _answer = value == 'English' ? 'Ask a question or start a Spirit Box session.' : 'Stel een vraag of start een Spirit Box-sessie.'; }); final p = await SharedPreferences.getInstance(); await p.setString('necro_spirit_language', value); }
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('spiritueel_history_v2');
    if (saved != null) { try { final decoded = jsonDecode(saved) as List; if (mounted) setState(() { _history.addAll(decoded.whereType<Map>().map((e) => Map<String,dynamic>.from(e))); if (_history.isNotEmpty) _answer = (_history.first['text'] ?? _answer).toString(); }); } catch (_) {} }
  }
  Future<void> _saveHistory() async { final p = await SharedPreferences.getInstance(); await p.setString('spiritueel_history_v2', jsonEncode(_history.take(100).toList())); }
  void _showResult(String text, {String kind = 'Reactie'}) {
    final now = DateTime.now();
    setState(() { _answer = text; _history.insert(0, {'time': now.toIso8601String(), 'text': text, 'kind': kind, 'mode': _mode, 'question': _question.text.trim()}); if (_history.length > 100) _history.removeLast(); });
    _saveHistory();
  }

  Future<void> _configureVoice({String? preset}) async {
    final v = preset ?? _voice;
    final locale = _language == 'English' ? 'en-US' : 'nl-NL';
    await _tts.setLanguage(locale); await _tts.setSpeechRate(_rate);
    await _tts.setPitch((v == 'Diep' || v == 'Deep') ? 0.72 : (v == 'Helder' || v == 'Clear') ? 1.18 : (v == 'Mannelijk' || v == 'Male') ? 0.88 : 1.0);
    try {
      final all = await _tts.getVoices;
      if (all is List) {
        final prefix = _language == 'English' ? 'en' : 'nl';
        final voices = all.whereType<Map>().where((x) => (x['locale']?.toString() ?? '').toLowerCase().startsWith(prefix)).toList();
        if (voices.isNotEmpty) {
          final wanted = (v.toLowerCase().contains('vrouw') || v.toLowerCase() == 'female') ? ['female','woman','fem','nl-nl-x-c'] : (v.toLowerCase().contains('man') || v.toLowerCase() == 'male') ? ['male','man','masc','nl-nl-x-d'] : <String>[];
          final match = wanted.isEmpty ? voices.first : voices.firstWhere((x) => wanted.any((w) => (x['name']?.toString().toLowerCase() ?? '').contains(w)), orElse: () => voices.first);
          await _tts.setVoice({'name': match['name'], 'locale': match['locale']});
        }
      }
    } catch (_) {}
  }
  Future<void> _speak(String text, {bool allVoices = false}) async {
    // Speak each response once; suppress an identical repeat within 20 seconds.
    final now = DateTime.now();
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return;
    if (normalized == _lastSpokenText.trim().toLowerCase() && now.difference(_lastSpokenAt).inSeconds < 20) return;
    _lastSpokenText = text.trim();
    _lastSpokenAt = now;
    await _tts.stop();
    await _configureVoice();
    await _tts.speak(text);
    await _tts.awaitSpeakCompletion(true);
  }
  String _lastRandomWord = '';
  String _pickFreshWord(List<String> words) {
    // Prefer words not used in the last two generated responses.
    final recent = _recentGeneratedWords.map((w) => w.toLowerCase()).toSet();
    final fresh = words.where((w) => !recent.contains(w.toLowerCase())).toList();
    final pool = fresh.isNotEmpty ? fresh : words;
    final picked = pool[_rng.nextInt(pool.length)];
    _recentGeneratedWords.add(picked);
    while (_recentGeneratedWords.length > 2) { _recentGeneratedWords.removeAt(0); }
    return picked;
  }

  Future<void> _randomWord() async {
    final words = _language == 'English' ? _wordsEn : _wordsNl;
    final result = _pickFreshWord(words);
    _showResult(result, kind: 'Spirit Box-woord');
    await _speak(result);
  }
  Future<void> _generateAnswerImage(String question, String answer) async {
    if (backendUrl.isEmpty) {
      if (mounted) setState(() => _imageError = _language == 'English'
          ? 'Image generation needs the online backend to be configured.'
          : 'Voor AI-afbeeldingen moet de online backend zijn ingesteld.');
      return;
    }
    setState(() { _imageBusy = true; _answerImage = null; _imageError = null; });
    try {
      final base = backendUrl.replaceFirst(RegExp(r'/+$'), '').replaceFirst(RegExp(r'/answer$'), '');
      final r = await http.post(Uri.parse('$base/generate-image'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode({'question': question, 'answer': answer, 'language': _language == 'English' ? 'en' : 'nl'}))
        .timeout(const Duration(seconds: 150));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception('Image service returned ${r.statusCode}');
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final encoded = data['imageBase64']?.toString();
      if (encoded == null || encoded.isEmpty) throw Exception('No image returned');
      if (mounted) setState(() => _answerImage = base64Decode(encoded));
    } catch (_) {
      if (mounted) setState(() => _imageError = _language == 'English'
          ? 'Could not create an image. Check the backend and API billing/configuration.'
          : 'Afbeelding maken is niet gelukt. Controleer de backend en API-instellingen/billing.');
    } finally { if (mounted) setState(() => _imageBusy = false); }
  }

  Future<void> _ask() async {
    final q = _question.text.trim(); if (q.isEmpty) { _showResult(_language == 'English' ? 'Please type or speak a question first.' : 'Typ of spreek eerst een vraag in.', kind: _language == 'English' ? 'Notice' : 'Melding'); return; }
    setState(() { _busy = true; _answerImage = null; _imageError = null; });
    try {
      String answer;
      if (backendUrl.isNotEmpty) {
        final r = await http.post(Uri.parse(backendUrl), headers: {'Content-Type':'application/json'}, body: jsonEncode({'question':q,'style':'dark_horror','language': _language == 'English' ? 'en' : 'nl'})).timeout(const Duration(seconds:20));
        if (r.statusCode >= 200 && r.statusCode < 300) { final d = jsonDecode(r.body) as Map<String,dynamic>; answer = (d['answer'] ?? (_language == 'English' ? 'No answer received.' : 'Geen antwoord ontvangen.')).toString(); }
        else { answer = _language == 'English' ? 'The online service did not respond. Try the offline Spirit Box.' : 'De online dienst reageerde niet. Probeer de offline Spirit Box.'; }
      } else {
        final promptsNl = [
          'De duivel fluistert: “Je hebt de deur geopend.”', '“Zeg de spreuk niet hardop.”', '“Het ritueel is begonnen.”', '“Ik sta achter je.”', '“Je bent niet alleen.”', '“Laat mij binnen.”', '“Sluit de poort voordat het te laat is.”', '“Je riep mij. Nu ben ik hier.”', '“De schaduw heeft je naam gehoord.”', '“Doof de kaars. Kijk niet om.”', '“Er is iets in de kelder.”', '“Drie kloppen. Dan kom ik.”', '“Je spiegel liegt.”', '“Vertrouw de stem niet.”', '“Ik ken je angst.”', '“De cirkel is gebroken.”', '“Het zegel houdt niet lang meer.”', '“Je hoort mijn stem, niet mijn naam.”', '“Vlucht zolang de deur nog open is.”', '“Te laat. Het is al binnen.”', '“Noem mijn naam en ik antwoord.”', '“Je ziel is niet van jou.”', '“De nacht is van mij.”', '“Er staat iemand in de gang.”', '“Niet kijken. Niet antwoorden.”', '“Ik wacht aan de andere kant.”', '“Je hebt iets wakker gemaakt.”', '“Het huis herinnert zich alles.”', '“De laatste kaars zal doven.”', '“Geen genade. Geen ontsnapping.”', '“Dit is een fictieve horrorreactie, geen bevestigde spirituele boodschap.”'
        ];
        final promptsEn = [
          'The Devil whispers: “You opened the door.”', '“Do not speak the spell aloud.”', '“The ritual has begun.”', '“I am standing behind you.”', '“You are not alone.”', '“Let me in.”', '“Close the gate before it is too late.”', '“You called me. Now I am here.”', '“The shadow has heard your name.”', '“Put out the candle. Do not turn around.”', '“There is something in the basement.”', '“Three knocks. Then I come.”', '“Your mirror is lying.”', '“Do not trust the voice.”', '“I know your fear.”', '“The circle is broken.”', '“The seal will not hold much longer.”', '“You hear my voice, not my name.”', '“Run while the door is still open.”', '“Too late. It is already inside.”', '“Say my name and I will answer.”', '“Your soul is not your own.”', '“The night belongs to me.”', '“Someone is standing in the hallway.”', '“Do not look. Do not answer.”', '“I am waiting on the other side.”', '“You have awakened something.”', '“This house remembers everything.”', '“The last candle will go out.”', '“No mercy. No escape.”', '“This is a fictional horror response, not a verified spirit message.”'
        ];
        final prompts = _language == 'English' ? promptsEn : promptsNl;
        answer = _pro ? '${['Stem 1','Stem 2','Stem 3'][_rng.nextInt(3)]} • ${prompts[_rng.nextInt(prompts.length)]}' : prompts[_rng.nextInt(prompts.length)];
      }
      _showResult(answer, kind: 'Antwoord op: $q');
      await _speak(answer);
      await _generateAnswerImage(q, answer);
    } catch (_) { _showResult(_language == 'English' ? 'Could not connect to the online service. You can still use offline word mode.' : 'Geen verbinding met de online dienst. Je kunt de offline woordmodus blijven gebruiken.', kind: _language == 'English' ? 'Notice' : 'Melding'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      final mic = await perm.Permission.microphone.request();
      if (!mic.isGranted) {
        if (!mounted) return;
        final permanentlyDenied = mic.isPermanentlyDenied;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_language == 'English'
            ? (permanentlyDenied ? 'Microphone permission is blocked. Open Android Settings > Apps > Spiritueel > Permissions.' : 'Microphone permission was not granted.')
            : (permanentlyDenied ? 'Microfoontoestemming is geblokkeerd. Open Android-instellingen > Apps > Spiritueel > Machtigingen.' : 'Microfoontoestemming is niet gegeven.')),
          action: permanentlyDenied ? SnackBarAction(label: _language == 'English' ? 'Settings' : 'Instellingen', onPressed: perm.openAppSettings) : null,
        ));
        return;
      }
      String? engineError;
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _listening = false);
          }
        },
        onError: (error) {
          engineError = error.errorMsg;
          if (mounted) setState(() => _listening = false);
        },
        debugLogging: true,
      );
      if (!available) {
        if (!mounted) return;
        final message = _language == 'English'
          ? 'Android speech recognition service could not be started. Check that Google speech services are enabled and updated.'
          : 'De Android-spraakdienst kon niet starten. Controleer of Spraakservices van Google ingeschakeld en bijgewerkt zijn.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(engineError == null ? message : '$message ($engineError)')));
        return;
      }
      final locales = await _speech.locales();
      final wanted = _language == 'English' ? ['en_US', 'en-US', 'en_GB', 'en-GB'] : ['nl_NL', 'nl-NL'];
      String? localeId;
      for (final wantedId in wanted) {
        for (final locale in locales) {
          if (locale.localeId.toLowerCase() == wantedId.toLowerCase()) { localeId = locale.localeId; break; }
        }
        if (localeId != null) break;
      }
      localeId ??= (await _speech.systemLocale())?.localeId;
      if (mounted) setState(() => _listening = true);
      await _speech.listen(
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        onResult: (result) {
          _question.value = TextEditingValue(text: result.recognizedWords, selection: TextSelection.collapsed(offset: result.recognizedWords.length));
          if (mounted) setState(() {});
        },
      );
    } catch (error) {
      if (mounted) {
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_language == 'English'
          ? 'Could not start speech recognition: $error'
          : 'Spraakherkenning kon niet starten: $error')));
      }
    }
  }
  Future<void> _startEvpRecording() async {
    if (_evpRecording) return;
    if (_autoScan || _listening) {
      _wordScanTimer?.cancel();
      _wordScanTimer = null;
      await _speech.stop();
      if (mounted) setState(() { _autoScan = false; _listening = false; });
    }
    final permission = await perm.Permission.microphone.request();
    if (!permission.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_language == 'English' ? 'Microphone permission is required to record EVP audio.' : 'Microfoontoestemming is nodig om EVP-audio op te nemen.')));
      return;
    }
    if (!await _evpRecorder.hasPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    final evpDir = Directory('${dir.path}/evp_sessions');
    await evpDir.create(recursive: true);
    final stamp = DateTime.now().toIso8601String().replaceAll(':','-');
    final path = '${evpDir.path}/evp_$stamp.m4a';
    try {
      await _evpRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100), path: path);
      if (!mounted) return;
      setState(() { _evpRecording = true; _evpSecondsLeft = _evpSelectedDuration; _evpStartedAt = DateTime.now(); _evpCurrentPath = path; });
      _evpTimer?.cancel();
      _evpTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) { timer.cancel(); return; }
        if (_evpSecondsLeft <= 1) { timer.cancel(); await _stopEvpRecording(); }
        else { setState(() => _evpSecondsLeft--); }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start recorder: $e')));
    }
  }

  Future<void> _stopEvpRecording() async {
    _evpTimer?.cancel();
    if (!_evpRecording) return;
    final path = await _evpRecorder.stop();
    final question = _evpQuestion.text.trim();
    if (path != null && await File(path).exists()) {
      final elapsed = _evpStartedAt == null ? _evpSelectedDuration : DateTime.now().difference(_evpStartedAt!).inSeconds.clamp(1, _evpSelectedDuration);
      final clip = {'path': path, 'question': question.isEmpty ? (_language == 'English' ? 'Unlabelled question' : 'Vraag zonder titel') : question, 'time': DateTime.now().toIso8601String(), 'durationSeconds': elapsed};
      _evpClips.insert(0, clip);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('necro_spirit_evp_clips_v1', jsonEncode(_evpClips));
    }
    if (mounted) setState(() { _evpRecording = false; _evpSecondsLeft = _evpSelectedDuration; _evpStartedAt = null; });
  }

  Future<void> _loadEvpClips() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('necro_spirit_evp_clips_v1');
    if (raw == null) return;
    try {
      final items = (jsonDecode(raw) as List).whereType<Map>().map((e) => Map<String,dynamic>.from(e)).where((e) => File((e['path'] ?? '').toString()).existsSync()).toList();
      if (mounted) setState(() { _evpClips..clear()..addAll(items); });
    } catch (_) {}
  }

  Future<void> _playEvpClip(String path) async {
    try {
      if (_evpPlaying) { await _evpPlayer.stop(); }
      await _evpPlayer.play(DeviceFileSource(path));
      if (mounted) setState(() => _evpPlaying = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not play recording: $e')));
    }
  }

  Future<void> _deleteEvpClip(Map<String,dynamic> clip) async {
    final path = (clip['path'] ?? '').toString();
    if (_evpCurrentPath == path && _evpRecording) await _stopEvpRecording();
    try { final f = File(path); if (await f.exists()) await f.delete(); } catch (_) {}
    _evpClips.remove(clip);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('necro_spirit_evp_clips_v1', jsonEncode(_evpClips));
    if (mounted) setState(() {});
  }

  Widget _buildEvpSession() {
    final en = _language == 'English';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(en ? 'EVP SESSION • QUESTION & LISTEN' : 'EVP-SESSIE • VRAAG & LUISTER', style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold,color:violet)),
      const SizedBox(height:8),
      Text(en ? 'Ask a question, choose a recording length, then capture continuous ambient audio. You decide when to ask the next question.' : 'Stel een vraag, kies de opnameduur en neem daarna onafgebroken omgevingsgeluid op. Jij bepaalt wanneer je de volgende vraag stelt.'),
      const SizedBox(height:12),
      TextField(controller:_evpQuestion,minLines:1,maxLines:3,decoration:InputDecoration(labelText:en ? 'Question (optional label)' : 'Vraag (optioneel label)',hintText:en ? 'e.g. Is anyone here?' : 'bijv. Is er iemand aanwezig?',border:const OutlineInputBorder())),
      const SizedBox(height:12),
      DropdownButtonFormField<int>(value:_evpSelectedDuration,decoration:InputDecoration(labelText:en ? 'Recording duration' : 'Opnameduur',border:const OutlineInputBorder()),items:const [15,30,60,90,120].map((seconds)=>DropdownMenuItem<int>(value:seconds,child:Text(seconds < 60 ? '$seconds seconds' : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2,'0')} minutes'))).toList(),onChanged:_evpRecording ? null : (value){if(value!=null)setState(()=>_evpSelectedDuration=value);}),
      const SizedBox(height:12),
      Card(color:const Color(0xFF141321),child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
        Icon(_evpRecording ? Icons.fiber_manual_record : Icons.mic_none, size:42, color:_evpRecording ? Colors.redAccent : violet),
        const SizedBox(height:8),
        Text(_formatEvpTime(_evpRecording ? _evpSecondsLeft : _evpSelectedDuration),style:const TextStyle(fontSize:34,fontWeight:FontWeight.bold,color:Color(0xFFE2CCFF))),
        const SizedBox(height:8),
        Text(_evpRecording ? (en ? 'Recording ambient audio…' : 'Omgevingsgeluid wordt opgenomen…') : (en ? 'Ready for ${_formatEvpTime(_evpSelectedDuration)} recording' : 'Klaar voor een opname van ${_formatEvpTime(_evpSelectedDuration)}'),textAlign:TextAlign.center),
        const SizedBox(height:12),
        SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_evpRecording ? _stopEvpRecording : _startEvpRecording,icon:Icon(_evpRecording ? Icons.stop_circle : Icons.fiber_manual_record),label:Text(_evpRecording ? (en ? 'Stop and save recording' : 'Stop en bewaar opname') : (en ? 'Record ${_formatEvpTime(_evpSelectedDuration)}' : 'Neem ${_formatEvpTime(_evpSelectedDuration)} op')))),
      ]))),
      const SizedBox(height:8),
      Text(en ? 'Saved EVP recordings' : 'Opgeslagen EVP-opnamen',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      if (_evpClips.isEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(en ? 'No EVP recordings saved yet.' : 'Nog geen EVP-opnamen opgeslagen.')),
      ..._evpClips.map((clip) { final path=(clip['path']??'').toString(); return Card(color:const Color(0xFF141321),child:ListTile(leading:IconButton(icon:const Icon(Icons.play_circle_fill,color:violet,size:32),onPressed:()=>_playEvpClip(path)),title:Text((clip['question']??'EVP').toString()),subtitle:Text('${_time(clip['time'])} • ${clip['durationSeconds'] ?? 0} s'),trailing:IconButton(tooltip:en?'Delete recording':'Opname verwijderen',icon:const Icon(Icons.delete_outline),onPressed:()=>_deleteEvpClip(clip)))); }),
      if (_evpDuration > Duration.zero && _evpClips.isNotEmpty) ...[
        const SizedBox(height:4),
        Slider(value:_evpPosition.inMilliseconds.clamp(0,_evpDuration.inMilliseconds).toDouble(),min:0,max:_evpDuration.inMilliseconds.toDouble().clamp(1,double.infinity),onChanged:(v)=>_evpPlayer.seek(Duration(milliseconds:v.round()))),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('${_evpPosition.inSeconds}s'),Text('${_evpDuration.inSeconds}s')]),
      ],
      const SizedBox(height:12),
      Text(en ? 'Transparency: recordings capture microphone audio only. Playback, amplification and interpretation do not verify spirit communication. Keep the room quiet and listen critically.' : 'Transparantie: opnamen leggen alleen microfoongeluid vast. Afspelen, versterken en interpreteren bewijzen geen spiritcommunicatie. Houd de ruimte stil en luister kritisch.',style:const TextStyle(fontSize:12,color:Colors.white54)),
    ]);
  }

  String _formatEvpTime(int seconds) { final m = seconds ~/ 60; final s = seconds % 60; return m > 0 ? '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}' : '00:${s.toString().padLeft(2,'0')}'; }

  Future<void> _clearHistory() async { setState(_history.clear); final p = await SharedPreferences.getInstance(); await p.remove('spiritueel_history_v2'); }
  String _time(dynamic raw) { try { final d = DateTime.parse(raw.toString()).toLocal(); return '${d.day.toString().padLeft(2,'0')}-${d.month.toString().padLeft(2,'0')}-${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'; } catch (_) { return ''; } }
  @override void dispose() { _wordScanTimer?.cancel(); _question.dispose(); _tts.stop(); _speech.stop(); _magSubscription?.cancel(); _accelSubscription?.cancel(); super.dispose(); }



  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(centerTitle: true, title: const Text('✦ NECRO SPIRIT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)), actions: [IconButton(tooltip:_language == 'English' ? 'Clear history' : 'Geschiedenis wissen', onPressed:_clearHistory, icon:const Icon(Icons.delete_outline))]),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors:[Color(0xFF241542),Color(0xFF101329)]), border: Border.all(color:const Color(0xFF9C6BFF), width:1.3), boxShadow:[BoxShadow(color:const Color(0xFF8C52FF).withOpacity(0.22), blurRadius:28, spreadRadius:1)]), child: Column(children:[
        const _EnergyOrb(), const SizedBox(height:8), const Text('NECRO SPIRIT • SPIRIT BOX PRO', style:TextStyle(fontSize:21,fontWeight:FontWeight.bold,letterSpacing:1.1)), const SizedBox(height:8), Text(_answer,textAlign:TextAlign.center,style:const TextStyle(fontSize:18,height:1.4)), if (_mode == 'Vraag' && _imageBusy) ...[const SizedBox(height:14), const CircularProgressIndicator(), const SizedBox(height:6), Text(_language == 'English' ? 'Creating a symbolic AI image…' : 'Symbolische AI-afbeelding wordt gemaakt…',style:const TextStyle(color:Colors.white70))], if (_mode == 'Vraag' && _answerImage != null) ...[const SizedBox(height:14), ClipRRect(borderRadius:BorderRadius.circular(16),child:Image.memory(_answerImage!,fit:BoxFit.cover,width:double.infinity,height:230,errorBuilder:(context,error,stack)=>const SizedBox.shrink())), const SizedBox(height:6), Text(_language == 'English' ? 'AI-generated artistic interpretation of the answer' : 'AI-gegenereerde artistieke interpretatie van het antwoord',textAlign:TextAlign.center,style:const TextStyle(fontSize:11,color:Colors.white60))], if (_mode == 'Vraag' && _imageError != null) ...[const SizedBox(height:8), Text(_imageError!,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,color:Colors.orangeAccent))], const SizedBox(height:12), OutlinedButton.icon(onPressed:()=>_speak(_answer),icon:const Icon(Icons.volume_up),label:Text(_language == 'English' ? 'Play again' : 'Opnieuw afspelen')),
      ])),
      const SizedBox(height:18),
      SegmentedButton<String>(segments:[ButtonSegment(value:'Vraag',label:Text(_language == 'English' ? 'Question' : 'Vraag'),icon:const Icon(Icons.chat_bubble_outline)),ButtonSegment(value:'Spirit Box',label:const Text('Spirit Box'),icon:const Icon(Icons.graphic_eq)),ButtonSegment(value:'Geschiedenis',label:Text(_language == 'English' ? 'History' : 'Geschiedenis'),icon:const Icon(Icons.history)),ButtonSegment(value:'EVP',label:const Text('EVP Session'),icon:const Icon(Icons.mic_none))], selected:{_mode}, onSelectionChanged:(v)=>setState(()=>_mode=v.first)),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:_language,decoration:InputDecoration(labelText:_language == 'English' ? 'App language • choose English or Dutch' : 'App-taal • kies Nederlands of Engels',border:const OutlineInputBorder()),items:const [DropdownMenuItem(value:'English',child:Text('🇬🇧 English (default)')),DropdownMenuItem(value:'Nederlands',child:Text('🇳🇱 Nederlands'))],onChanged:(v) { if (v != null) _setLanguage(v); }),
      const SizedBox(height:16),
      Card(color: const Color(0xFF141321), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_language == 'English' ? 'AUTOMATIC WORD SCAN' : 'AUTOMATISCHE WOORDSCAN', style: const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        const SizedBox(height:6),
        Text(_language == 'English' ? 'The microphone checks recognized speech for words from the built-in list. The app also speaks an occasional random word even when no speech is recognized. Random words are software-generated effects, not paranormal signals.' : 'De microfoon controleert herkende spraak op woorden uit de ingebouwde lijst. Daarnaast spreekt de app af en toe een willekeurig woord uit, ook als er geen spraak wordt herkend. Dit zijn softwarematig gegenereerde effecten, geen paranormale signalen.'),
        const SizedBox(height:10),
        SizedBox(width:double.infinity, child: FilledButton.icon(onPressed:_toggleAutoScan, icon:Icon(_autoScan ? Icons.stop_circle_outlined : Icons.hearing), label:Text(_autoScan ? (_language == 'English' ? 'Stop automatic scan' : 'Stop automatische scan') : (_language == 'English' ? 'Start automatic scan' : 'Start automatische scan')))),
        const SizedBox(height:8),
        Text(_language == 'English' ? 'Sensors in use' : 'Gebruikte sensoren', style: const TextStyle(fontWeight:FontWeight.bold)),
        Text('• ${_language == 'English' ? 'Microphone / speech recognition' : 'Microfoon / spraakherkenning'}\n• ${_language == 'English' ? 'Magnetometer (magnetic-field estimate)' : 'Magnetometer (schatting magnetisch veld)'}\n• ${_language == 'English' ? 'Accelerometer (device movement)' : 'Accelerometer (beweging toestel)'}'),
        const SizedBox(height:6),
        Text('${_language == 'English' ? 'Sensor status' : 'Sensorstatus'}: $_sensorStatus', style: const TextStyle(color:Colors.white70,fontSize:12)),
        Text('${_language == 'English' ? 'Magnetic field magnitude' : 'Sterkte magnetisch veld'}: ${_magneticMicrotesla == null ? '—' : '${_magneticMicrotesla!.toStringAsFixed(1)} µT'}', style: const TextStyle(fontSize:13)),
        Text('${_language == 'English' ? 'Motion magnitude' : 'Bewegingswaarde'}: ${_motionMagnitude == null ? '—' : _motionMagnitude!.toStringAsFixed(2)} m/s²', style: const TextStyle(fontSize:13)),
        const SizedBox(height:4),
        Text(_language == 'English' ? 'Sensor readings vary by phone and environment. The magnetometer is not a calibrated EMF meter and cannot detect spirits.' : 'Sensorwaarden verschillen per telefoon en omgeving. De magnetometer is geen gekalibreerde EMF-meter en kan geen geesten detecteren.', style: const TextStyle(fontSize:12,color:Colors.white54)),
      ]))),
      const SizedBox(height:16),
      if (_mode == 'Spirit Box') ...[
        Text(_language == 'English' ? 'Spirit Box Pro • offline' : 'Spirit Box Pro • offline',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)), const SizedBox(height:6), Text(_language == 'English' ? 'Responses are randomly selected from a built-in word database. The app does not communicate with or detect spirits.' : 'Reacties worden willekeurig gekozen uit een ingebouwde woorden database. De app praat niet met geesten en detecteert geen geesten.'), const SizedBox(height:12),
        FilledButton.icon(onPressed:_busy?null:_randomWord,icon:const Icon(Icons.bolt),label:Text(_language == 'English' ? 'Generate responses' : 'Genereer reacties')), const SizedBox(height:8),
        OutlinedButton.icon(onPressed:_busy?null:() async { setState(()=>_busy=true); try { for (var i=0;i<(_pro?10:5);i++) { if (!mounted) break; await _randomWord(); await Future.delayed(const Duration(milliseconds:650)); } } finally { if(mounted)setState(()=>_busy=false); } },icon:const Icon(Icons.play_circle_outline),label:Text(_language == 'English' ? 'Start session (${_pro?10:5} responses)' : 'Start sessie (${_pro?10:5} reacties)')),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(_language == 'English' ? 'Spirit Box Pro' : 'Spirit Box Pro'),subtitle:Text(_language == 'English' ? 'More words and longer sessions' : 'Meer woorden en langere sessies'),value:_pro,onChanged:(v)=>setState(()=>_pro=v)),
      ] else if (_mode == 'Vraag') ...[
        Text(_language == 'English' ? 'Ask a question' : 'Stel een vraag',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
        TextField(controller:_question,minLines:2,maxLines:4,textInputAction:TextInputAction.done,decoration:InputDecoration(hintText:_language == 'English' ? 'Type or speak your question…' : 'Typ je vraag of spreek hem in…',filled:true,fillColor:const Color(0xFF141321),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16))),onSubmitted:(_)=>_ask()),
        const SizedBox(height:8), Row(children:[Expanded(child:OutlinedButton.icon(onPressed:_toggleListen,icon:Icon(_listening?Icons.stop:Icons.mic),label:Text(_listening ? (_language == 'English' ? 'Stop listening' : 'Stop luisteren') : (_language == 'English' ? 'Speak question' : 'Vraag inspreken')))),const SizedBox(width:8),Expanded(child:FilledButton.icon(onPressed:_busy?null:_ask,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.auto_awesome),label:Text(_busy ? (_language == 'English' ? 'Working…' : 'Bezig…') : (_language == 'English' ? 'Answer question' : 'Beantwoorden'))))]),
        const SizedBox(height:6), Text(backendUrl.isEmpty ? (_language == 'English' ? 'Responses are generated from prompts or a configured online AI service. This app does not communicate with or detect spirits.' : 'Reacties komen uit reflectieprompts of een ingestelde online AI-dienst. Deze app praat niet met geesten en detecteert geen geesten.') : (_language == 'English' ? 'Online AI response service enabled; no spirit communication or detection.' : 'Online AI-reactieservice ingeschakeld; geen communicatie met of detectie van geesten.'),style:const TextStyle(fontSize:12,color:Colors.white60)),
      ] else if (_mode == 'EVP') ...[
        _buildEvpSession(),
      ] else ...[
        Row(children:[Expanded(child:Text(_language == 'English' ? 'Saved session history' : 'Opgeslagen sessiegeschiedenis',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),TextButton(onPressed:_clearHistory,child:Text(_language == 'English' ? 'Clear' : 'Wissen'))]),
        if (_history.isEmpty) Padding(padding:const EdgeInsets.symmetric(vertical:20),child:Text(_language == 'English' ? 'No responses have been saved yet.' : 'Er zijn nog geen opgeslagen reacties.')) else ..._history.map((item)=>Card(color:const Color(0xFF141321),child:ListTile(leading:const Icon(Icons.history,color:violet),title:Text((item['text']??'').toString()),subtitle:Text('${_time(item['time'])} • ${(item['kind']??(_language == 'English' ? 'Response' : 'Reactie'))}'),onTap:()=>_speak((item['text']??'').toString())))),
      ],
      const SizedBox(height:20), Text(_language == 'English' ? 'VOICE SETTINGS' : 'STEMINSTELLINGEN',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:8),
      DropdownButtonFormField<String>(value:_voice,decoration:InputDecoration(labelText:_language == 'English' ? 'Preferred voice' : 'Voorkeursstem',border:const OutlineInputBorder()),items:_language == 'English' ? const [DropdownMenuItem(value:'Female',child:Text('Female (if available)')),DropdownMenuItem(value:'Male',child:Text('Male (if available)')),DropdownMenuItem(value:'Standard',child:Text('Standard')),DropdownMenuItem(value:'Deep',child:Text('Deep')),DropdownMenuItem(value:'Clear',child:Text('Higher / clearer'))] : const [DropdownMenuItem(value:'Vrouwelijk (indien beschikbaar)',child:Text('Vrouwelijk (indien beschikbaar)')),DropdownMenuItem(value:'Mannelijk',child:Text('Mannelijk (indien beschikbaar)')),DropdownMenuItem(value:'Standaard',child:Text('Standaard')),DropdownMenuItem(value:'Diep',child:Text('Dieper')),DropdownMenuItem(value:'Helder',child:Text('Hoger / helderder'))],onChanged:(v)=>setState(()=>_voice=v??(_language == 'English' ? 'Standard' : 'Standaard'))),
      const SizedBox(height:4),Text('${_language == 'English' ? 'Speech rate' : 'Spreeksnelheid'}: ${_rate.toStringAsFixed(2)}'),Slider(value:_rate,min:0.25,max:0.7,divisions:9,label:_rate.toStringAsFixed(2),onChanged:(v)=>setState(()=>_rate=v)),
      const SizedBox(height:14), Text(_language == 'English' ? 'Sessions are stored on this device. Voices depend on your speech engine. Responses are software-generated and are not messages from verified spirits.' : 'Sessies worden lokaal op dit toestel bewaard. Stemmen hangen af van de spraakengine. Reacties worden door software samengesteld en zijn geen geverifieerde boodschappen van geesten.',textAlign:TextAlign.center,style:TextStyle(fontSize:12,color:Colors.white54)),
    ])));
}
