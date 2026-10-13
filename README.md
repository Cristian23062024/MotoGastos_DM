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
  cámara real; se puede usar "Elegir foto de la galería" para probar el
  resto del flujo desde un emulador).

## 2. Generar el proyecto nativo (Android/iOS)

Este repositorio trae solo la capa `lib/` + `pubspec.yaml` (el código
Dart). Los proyectos nativos de Android/iOS se generan con la herramienta
de Flutter, para no arrastrar plantillas nativas ya desactualizadas:

Clonar el repositorio:

```bash
git clone https://github.com/Cristian23062024/MotoGastos_DM.git
```

Dentro del proyecto ejecutar:

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

(Revisar también las instrucciones de instalación de los paquetes `camera`
e `image_picker` en pub.dev por si la versión que instale pide algo
adicional — cambian de vez en cuando.)

## 4. Configurar el reconocimiento por IA

El reconocimiento envía la foto de la cámara a **Gemini** (Google AI) y
recibe un JSON estructurado con marca, línea, categoría, cilindraje, año,
peso, consumo (km/l), tipo de motor, uso y confianza. Cada dato se muestra
en su tarjeta de la ficha técnica, y el consumo alimenta el rendimiento
km/galón del cálculo de gasolina. La API key **nunca se escribe en el
código ni se empaqueta como asset** (eso la dejaría extraíble del
.apk/.ipa instalado); se pasa en tiempo de compilación:

1. Copiar `env.json.example` a `env.json`
2. Complétar con tu API key de Gemini (se la puede crear en 
   https://aistudio.google.com/apikey). `GEMINI_MODEL` es opcional; por
   defecto se usa `gemini-flash-latest`:

   ```json
   {
     "GEMINI_API_KEY": "AIza...",
     "GEMINI_MODEL": "gemini-flash-latest"
   }
   ```

   Si se prefiere Claude, dejar `GEMINI_API_KEY` vacío y llena
   `ANTHROPIC_API_KEY` y `ANTHROPIC_MODEL`. Gemini tiene prioridad cuando
   ambos están configurados.

3. Correr o compilar así:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

Si no configura nada, la app funciona igual en **modo demostración**:
usa un resultado simulado (`MockRecognitionService`) para que pueda
probar todo el flujo — cámara, resultado, cálculo de gastos — sin
depender de una API externa. Verá un aviso pequeño de "modo
demostración" mientras analiza.

### Para producción real

No llamar la API de visión directamente desde el celular en una versión
publicada: aunque `--dart-define` evita que la clave quede en texto
plano dentro del código fuente, sigue siendo extraíble del binario
compilado con suficiente esfuerzo. Lo correcto es poner un backend propio
(aunque sea una función serverless pequeña) que reciba la foto del
celular, guarde la API key del lado del servidor, y le devuelva el
resultado a la app. `GeminiVisionRecognitionService`
(`lib/services/gemini_vision_recognition_service.dart`) ya está aislado
detrás de la interfaz `MotorcycleRecognitionService`, así que apuntar al
backend es solo cambiar el `endpoint` que recibe esa clase.

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
  services/               Reconocimiento (interfaz + Gemini + Claude + mock)
  state/                  AppState (estado compartido entre pantallas)
  screens/                Las 5 pantallas del flujo
  widgets/                Componentes reutilizables
```

## 7. Roadmap:

- Backend propio para no exponer la API key (ver sección 4).
- Guardar un historial de motos escaneadas (hoy cada "Escanear otra
  moto" empieza de cero).
- Selección de ciudad para afinar el precio de la gasolina y el
  impuesto por municipio.
