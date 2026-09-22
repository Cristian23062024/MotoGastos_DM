# MotoGastos

App Flutter que usa la cámara del celular para reconocer una motocicleta
(marca, línea, cilindraje aproximado) con IA, y a partir de eso estima el
gasto anual de tenerla en Colombia: SOAT, revisión tecnomecánica, impuesto
vehicular, gasolina y mantenimiento. Todos los valores quedan editables
dentro de la app.

Este código corresponde al flujo ya validado en el prototipo de diseño
(Bienvenida → Cámara → Analizando → Resultado → Gastos), con la misma
paleta y tipografía (Space Grotesk + IBM Plex Sans).

## 1. Requisitos

- Flutter estable reciente (`flutter --version`), con soporte para Android
  y/o iOS.
- Un celular físico para probar la cámara (el emulador/simulador no tiene
  cámara real; puedes usar "Elegir foto de la galería" para probar el
  resto del flujo desde un emulador).

## 2. Generar el proyecto nativo (Android/iOS)

Este repositorio trae solo la capa `lib/` + `pubspec.yaml` (el código
Dart). Los proyectos nativos de Android/iOS se generan con la herramienta
de Flutter, para no arrastrar plantillas nativas ya desactualizadas:

```bash
flutter create --platforms=android,ios --org com.tuempresa motogastos
```

Luego copia dentro del proyecto generado:

- este `lib/` (reemplazando el que trae por defecto),
- este `pubspec.yaml` (o copia solo la sección `dependencies:`),
- `analysis_options.yaml`, `.gitignore`, `env.json.example`.

Y dentro del proyecto:

```bash
flutter pub get
```

## 3. Permisos de cámara y galería

**Android** — en `android/app/src/main/AndroidManifest.xml`, dentro de
`<manifest>` (antes de `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

**iOS** — en `ios/Runner/Info.plist`, dentro de `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>MotoGastos usa la cámara para reconocer tu moto.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>MotoGastos necesita acceso a tus fotos para elegir una imagen de tu moto.</string>
```

(Revisa también las instrucciones de instalación de los paquetes `camera`
e `image_picker` en pub.dev por si la versión que instales pide algo
adicional — cambian de vez en cuando.)

## 4. Configurar el reconocimiento por IA

El reconocimiento llama a la API de visión de Anthropic (Claude) con la
foto tomada. La API key **nunca se escribe en el código ni se empaqueta
como asset** (eso la dejaría extraíble del .apk/.ipa instalado); se pasa
en tiempo de compilación:

1. Copia `env.json.example` a `env.json` (ya está en `.gitignore`, no se
   sube al repo).
2. Complétalo con tu API key y el id del modelo de Claude con visión que
   quieras usar (revisa el vigente en
   https://docs.claude.com/en/docs/about-claude/models, cambia con el
   tiempo):

   ```json
   {
     "ANTHROPIC_API_KEY": "sk-ant-...",
     "ANTHROPIC_MODEL": "claude-sonnet-..."
   }
   ```

3. Corre o compila así:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

Si no configuras nada, la app funciona igual en **modo demostración**:
usa un resultado simulado (`MockRecognitionService`) para que puedas
probar todo el flujo — cámara, resultado, cálculo de gastos — sin
depender de una API externa. Verás un aviso pequeño de "modo
demostración" mientras analiza.

### Para producción real

No llames la API de visión directamente desde el celular en una versión
publicada: aunque `--dart-define` evita que la clave quede en texto
plano dentro del código fuente, sigue siendo extraíble del binario
compilado con suficiente esfuerzo. Lo correcto es poner un backend propio
(aunque sea una función serverless pequeña) que reciba la foto del
celular, guarde la API key del lado del servidor, y le devuelva el
resultado a la app. `ClaudeVisionRecognitionService`
(`lib/services/claude_vision_recognition_service.dart`) ya está aislado
detrás de la interfaz `MotorcycleRecognitionService`, así que apuntar a
tu backend es solo cambiar el `endpoint` que recibe esa clase.

## 5. Tarifas de Colombia usadas (2026)

En `lib/data/colombia_rates_2026.dart`, con las fuentes en los
comentarios del archivo. Resumen:

- **SOAT**: por rango de cilindraje (≤50, ≤100, 101–200, >200 cc).
- **Tecnomecánica**: valor promedio del rango oficial 2026.
- **Impuesto vehicular**: avalúo estimado × 1,5 % para motos de más de
  125 cc (exentas las de 125 cc o menos).
- **Gasolina**: se calcula como `(km al año ÷ rendimiento en km/galón) ×
  precio del galón`, con valores de referencia nacionales.
- **Mantenimiento**: estimado anual de aceite, frenos y ajustes.

Son valores de referencia, no una cotización oficial — la app deja
editar cada uno, y hay que revisarlos cada año porque cambian con
decretos, la UVT y el mercado.

## 6. Estructura del código

```
lib/
  main.dart               Punto de entrada
  app.dart                MaterialApp + Provider
  theme/                  Colores y tipografía
  models/                 Motorcycle, ExpenseInputs
  data/                   Tarifas Colombia 2026
  services/               Reconocimiento (interfaz + Claude + mock)
  state/                  AppState (estado compartido entre pantallas)
  screens/                Las 5 pantallas del flujo
  widgets/                Componentes reutilizables
```

## 7. Qué falta / próximos pasos sugeridos

- Backend propio para no exponer la API key (ver sección 4).
- Guardar un historial de motos escaneadas (hoy cada "Escanear otra
  moto" empieza de cero).
- Selección de ciudad para afinar el precio de la gasolina y el
  impuesto por municipio.
- Tests automatizados (`flutter test`) para `ExpenseInputs` y las
  tarifas — no se corrieron en este entorno porque no tiene el SDK de
  Flutter instalado; ver nota abajo.

## Nota sobre verificación

Este código se escribió y revisó manualmente (imports, tipos, llaves
balanceadas) pero **no se compiló** porque el entorno donde se generó no
tiene el SDK de Flutter/Dart disponible. Antes de darlo por bueno, corre:

```bash
flutter pub get
flutter analyze
flutter run
```

y avísame si `flutter analyze` marca algo — lo corregimos.
