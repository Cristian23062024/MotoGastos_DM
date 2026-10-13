import 'dart:convert';

/// Instrucción común para cualquier modelo de visión: describe exactamente
/// el JSON que `Motorcycle.fromJson` sabe leer, para que cada campo que
/// devuelva la IA aparezca en su lugar en la ficha técnica y en los gastos.
const String recognitionPrompt = '''
Eres un experto en motocicletas que circulan en Colombia. Observa la foto
y responde EXCLUSIVAMENTE con un objeto JSON (sin texto adicional, sin
explicación, sin bloque de código Markdown) con esta forma exacta:

{
  "brand": "marca, por ejemplo Yamaha",
  "model": "línea o referencia, por ejemplo FZ 150",
  "category": "tipo de moto: Naked, Scooter, Enduro, Deportiva, Trabajo, Touring, etc.",
  "engine_cc": 150,
  "estimated_year": 2022,
  "estimated_weight_kg": 127,
  "fuel_efficiency_km_l": 42,
  "engine_type": "4 Tiempos",
  "usage": "Uso urbano",
  "confidence": 0.85
}

"engine_cc" es el cilindraje estimado en centímetros cúbicos (entero).
"estimated_year" es el año aproximado de fabricación (entero, o null si de
verdad no se puede estimar). "estimated_weight_kg" es el peso en seco
aproximado en kg (entero, o null). "fuel_efficiency_km_l" es el consumo
promedio en ciclo urbano en kilómetros por litro (número, o null si es
eléctrica). "engine_type" es "4 Tiempos", "2 Tiempos" o "Eléctrica".
"usage" es el uso típico en pocas palabras ("Uso urbano", "Trabajo",
"Aventura", "Deportivo", "Viajes"). "confidence" es un número entre 0 y 1
que refleja qué tan seguro estás. Si no reconoces la moto con certeza, da
tu mejor estimación razonada igual y baja "confidence" en vez de dejar
campos vacíos. Si en la foto no hay ninguna moto, responde con
"brand": "Sin moto" y "confidence": 0.
''';

/// El modelo a veces envuelve el JSON en una frase o en ```json ... ```
/// pese a la instrucción; esto busca el primer objeto `{ ... }` del texto
/// y lo decodifica, en vez de asumir que la respuesta es JSON puro.
Map<String, dynamic>? extractJsonObject(String text) {
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start == -1 || end == -1 || end < start) return null;
  final candidate = text.substring(start, end + 1);
  try {
    final decoded = jsonDecode(candidate);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Tipo MIME de la foto según su extensión (las cámaras entregan JPEG).
String imageMimeTypeFor(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic')) return 'image/heic';
  return 'image/jpeg';
}
