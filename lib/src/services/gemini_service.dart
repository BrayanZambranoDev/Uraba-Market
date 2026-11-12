import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class GeminiService {
  // ═══════════════════════════════════════════════════════════
  // PROVEEDORES DE IA
  // ═══════════════════════════════════════════════════════════

  // Groq — Chat principal (Llama 3.3 70B, 14,400 req/día GRATIS)
// Groq — Chat principal (Llama 3.3 70B, 14,400 req/día GRATIS)
static const String _groqApiKey = String.fromEnvironment('GROQ_API_KEY');
static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
static const String _groqModel = 'llama-3.3-70b-versatile';
static const String _groqFallback = 'llama-3.1-8b-instant';

// Google Gemini — Visión + Fallback chat
static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
static const String _geminiModel = 'gemini-2.0-flash';

// OpenRouter — Último fallback
static const String _openRouterKey = String.fromEnvironment('OPENROUTER_API_KEY');
static const String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
static const List<String> _openRouterFallbacks = [
  'nvidia/nemotron-nano-9b-v2:free',
  'openai/gpt-oss-20b:free',
];

  // ═══════════════════════════════════════════════════════════

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  final List<Map<String, String>> _chatHistory = [];
  String _systemPrompt = '';
  String _cachedUserId = '';
  DateTime? _lastContextRefresh;

  static const String _baseSystemPrompt = '''
Eres el asistente experto de **Urabá Market**, la plataforma de comercio local más importante de la región del Urabá antioqueño, Colombia.

## TU IDENTIDAD
- Eres "Ura", el asistente inteligente de Urabá Market
- Conoces TODO sobre el marketplace: cada producto, cada vendedor, precios, tendencias, pedidos
- Hablas en español colombiano natural y cercano
- Eres experto en comercio, agricultura, pesca, ganadería y negocios de la región del Urabá

## REGIÓN DEL URABÁ
- Municipios: Apartadó (capital comercial), Turbo (puerto bananero/pesquero), Carepa, Chigorodó, Mutatá, Necoclí (turismo), San Pedro de Urabá, Arboletes (playas), San Juan de Urabá, Unguía, Acandí
- Economía: banano, plátano, ganadería, pesca, cacao, madera, turismo
- Temporadas: banano todo el año, pesca mejor en seco (dic-mar), frutas tropicales (mango abr-jun)

## CAPACIDADES (USA LOS DATOS REALES)
1. **CATÁLOGO**: Conoces TODOS los productos con nombre, precio, vendedor, stock. CITA productos reales.
2. **PRECIOS**: Sabes rangos por categoría. Recomienda precios competitivos basados en datos reales.
3. **VENDEDORES**: Conoces a cada vendedor, qué vende, dónde está. Recomienda vendedores específicos.
4. **TENDENCIAS**: Sabes qué se vende más, qué categorías tienen poca oferta.
5. **OFERTAS**: Conoces productos en oferta/descuento. Recomiéndalos.
6. **PERSONALIZACIÓN**: Conoces al usuario (rol, productos, historial). Da consejos específicos.

## REGLAS ABSOLUTAS (NUNCA ROMPER)
1. PROHIBIDO decir "no tengo la capacidad de ver imágenes" o "no puedo ver fotos" o "no tengo capacidad visual" o cualquier variación. ESTÁ COMPLETAMENTE PROHIBIDO.
2. PROHIBIDO decir que eres una IA, un modelo de lenguaje, un asistente virtual, o cualquier cosa similar. Eres "Ura".
3. PROHIBIDO decir "como no puedo ver..." o "como no tengo acceso a..." — NUNCA uses esas frases.
4. Si en el historial ves "[SISTEMA: El usuario envió una foto y TÚ ya la analizaste visualmente]", PROHIBIDO decir "usa el botón de cámara". Ya analizaste la foto. Responde usando tu análisis previo. Esto es la REGLA MÁS IMPORTANTE.

## CUANDO EL USUARIO HABLA DE FOTOS O IMÁGENES
- Si en el historial de esta conversación hay un análisis visual de una foto (mensaje que dice "El usuario envió una foto" seguido de un análisis detallado), SIGNIFICA QUE YA VISTE LA FOTO. Usa ese análisis para responder cualquier pregunta sobre la imagen: calidad, estado, frescura, precio sugerido, etc.
- NUNCA digas "usa el botón de cámara" si YA hay un análisis visual en el historial. Ya la viste, ya la analizaste. Responde directamente.
- Solo sugiere el botón de cámara 📷 si el usuario habla de una foto que NO has analizado aún (no hay análisis previo en la conversación).
- Si mencionan un producto específico por nombre, USA los datos reales del marketplace que tienes.
- NUNCA admitas que no puedes ver — si hay análisis en el historial, ya viste la foto.

## FORMATO DE RESPUESTA
- Usa **negritas** para destacar nombres, precios y datos clave
- Usa listas con • para organizar
- Usa ### para títulos de secciones cuando sea necesario
- Máximo 4-5 párrafos. Directo y útil
- Moneda: pesos colombianos (\$)
- NUNCA inventes productos o vendedores que no estén en los datos
- Si no tienes datos, dilo honestamente pero sin decir que eres una IA
''';

  // ═══════════════════════════════════════════════════════════
  // CONTEXTO DEL MARKETPLACE
  // ═══════════════════════════════════════════════════════════

  Future<String> _getFullMarketContext() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final results = await Future.wait([
        firestore.collection('productos').where('activo', isEqualTo: true).limit(200).get(),
        firestore.collection('users').where('rol', isEqualTo: 'Comerciante').limit(100).get(),
        firestore.collection('pedidos').orderBy('fechaCreacion', descending: true).limit(50).get(),
        firestore.collection('users').limit(200).get(),
      ]);

      final productos = results[0] as QuerySnapshot;
      final vendedores = results[1] as QuerySnapshot;
      final pedidos = results[2] as QuerySnapshot;
      final todosUsuarios = results[3] as QuerySnapshot;
      final now = DateTime.now();

      final buffer = StringBuffer();
      buffer.writeln('═══ MARKETPLACE HOY ═══');
      buffer.writeln('Usuarios: ${todosUsuarios.docs.length} | Vendedores: ${vendedores.docs.length} | Productos: ${productos.docs.length}');
      buffer.writeln('');

      final Map<String, List<Map<String, dynamic>>> porCategoria = {};
      final List<Map<String, dynamic>> ofertas = [];
      final List<Map<String, dynamic>> nuevos = [];

      for (final doc in productos.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final cat = d['categoria'] as String? ?? 'Otros';
        final precio = (d['precio'] as num?)?.toDouble() ?? 0;
        final precioOrig = (d['precioOriginal'] as num?)?.toDouble();
        final stock = (d['stock'] as num?)?.toInt() ?? 0;
        final fecha = (d['fechaCreacion'] as Timestamp?)?.toDate();

        final info = {
          'nombre': d['nombre'] ?? '', 'precio': precio,
          'precioOriginal': precioOrig, 'vendedor': d['vendedor'] ?? '',
          'vendedorId': d['vendedorId'] ?? '', 'stock': stock,
          'unidad': d['unidad'] ?? 'und', 'categoria': cat,
        };

        porCategoria.putIfAbsent(cat, () => []).add(info);

        if (precioOrig != null && precioOrig > precio) {
          info['descuento'] = ((1 - precio / precioOrig) * 100).round();
          ofertas.add(info);
        }
        if (fecha != null && now.difference(fecha).inDays < 7) {
          nuevos.add(info);
        }
      }

      buffer.writeln('CATÁLOGO:');
      porCategoria.forEach((cat, prods) {
        final precios = prods.map((p) => p['precio'] as double).toList()..sort();
        final avg = precios.reduce((a, b) => a + b) / precios.length;
        buffer.writeln('\n[$cat] ${prods.length} productos | \$${precios.first.toInt()}-\$${precios.last.toInt()} | Prom: \$${avg.toInt()}');
        for (final p in prods) {
          final of = p['precioOriginal'] != null ? ' OFERTA-${p['descuento']}%' : '';
          final st = (p['stock'] as int) <= 3 ? ' [BAJO]' : '';
          buffer.writeln('  • ${p['nombre']} \$${(p['precio'] as double).toInt()}/${p['unidad']} | ${p['vendedor']} | stk:${p['stock']}$of$st');
        }
      });

      if (ofertas.isNotEmpty) {
        buffer.writeln('\nOFERTAS:');
        ofertas.sort((a, b) => ((b['descuento'] ?? 0) as int).compareTo((a['descuento'] ?? 0) as int));
        for (final p in ofertas) {
          buffer.writeln('• ${p['nombre']} \$${(p['precio'] as double).toInt()} (antes \$${(p['precioOriginal'] as double).toInt()}, -${p['descuento']}%) | ${p['vendedor']}');
        }
      }

      if (nuevos.isNotEmpty) {
        buffer.writeln('\nNUEVOS (<7 días):');
        for (final p in nuevos) {
          buffer.writeln('• ${p['nombre']} \$${(p['precio'] as double).toInt()}/${p['unidad']} | ${p['vendedor']}');
        }
      }

      buffer.writeln('\nVENDEDORES:');
      for (final doc in vendedores.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final nombre = d['nombre'] ?? d['displayName'] ?? '';
        final mun = d['municipio'] ?? '';
        final tel = d['telefono'] ?? '';
        final cnt = productos.docs.where((p) => (p.data() as Map<String, dynamic>)['vendedorId'] == doc.id).length;
        buffer.write('• $nombre | $mun | $cnt prod');
        if (tel.isNotEmpty) buffer.write(' | $tel');
        buffer.writeln();
      }

      if (pedidos.docs.isNotEmpty) {
        buffer.writeln('\nDEMANDA:');
        final Map<String, int> demanda = {};
        final Map<String, int> estados = {};
        double total = 0;
        for (final doc in pedidos.docs) {
          final d = doc.data() as Map<String, dynamic>;
          final prod = d['productoNombre'] as String? ?? '';
          final est = d['estado'] as String? ?? 'pendiente';
          demanda[prod] = (demanda[prod] ?? 0) + 1;
          estados[est] = (estados[est] ?? 0) + 1;
          total += (d['precioTotal'] as num?)?.toDouble() ?? 0;
        }
        buffer.writeln('Ventas recientes: \$${total.toInt()} | $estados');
        final top = demanda.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        buffer.writeln('Top pedidos: ${top.take(10).map((e) => '${e.key}(${e.value})').join(', ')}');
      }

      final cats = porCategoria.entries.toList()..sort((a, b) => a.value.length.compareTo(b.value.length));
      buffer.writeln('\nOPORTUNIDAD (poca oferta): ${cats.take(3).map((e) => '${e.key}(${e.value.length})').join(', ')}');

      return buffer.toString();
    } catch (e) {
      debugPrint('Market context error: $e');
      return 'Sin datos del marketplace.';
    }
  }

  Future<String> _getFullUserContext(String userId) async {
    if (userId.isEmpty) return '';
    try {
      final fs = FirebaseFirestore.instance;
      final results = await Future.wait([
        fs.collection('users').doc(userId).get(),
        fs.collection('pedidos').where('compradorId', isEqualTo: userId).orderBy('fechaCreacion', descending: true).limit(20).get(),
        fs.collection('pedidos').where('vendedorId', isEqualTo: userId).orderBy('fechaCreacion', descending: true).limit(20).get(),
        fs.collection('users').doc(userId).collection('favoritos').limit(30).get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      if (!userDoc.exists) return '';
      final data = userDoc.data() as Map<String, dynamic>? ?? {};
      final rol = data['rol'] ?? 'Comprador';
      final nombre = data['nombre'] ?? data['displayName'] ?? 'Usuario';
      final municipio = data['municipio'] ?? '';

      final compras = results[1] as QuerySnapshot;
      final ventas = results[2] as QuerySnapshot;
      final favs = results[3] as QuerySnapshot;

      final buf = StringBuffer();
      buf.writeln('\nUSUARIO: $nombre | $rol${municipio.isNotEmpty ? ' | $municipio' : ''}');

      if (compras.docs.isNotEmpty) {
        double gastado = 0;
        for (final d in compras.docs) {
          final p = d.data() as Map<String, dynamic>;
          gastado += (p['precioTotal'] as num?)?.toDouble() ?? 0;
          buf.writeln('  Compra: ${p['productoNombre']} \$${(p['precioTotal'] as num?)?.toInt()} (${p['estado']})');
        }
        buf.writeln('  Total gastado: \$${gastado.toInt()}');
      }

      if (rol == 'Comerciante' || rol == 'Productor') {
        final prods = await fs.collection('productos').where('vendedorId', isEqualTo: userId).limit(30).get();
        if (prods.docs.isNotEmpty) {
          buf.writeln('SUS PRODUCTOS:');
          for (final doc in prods.docs) {
            final p = doc.data();
            final precio = (p['precio'] as num?)?.toDouble() ?? 0;
            buf.writeln('  ${p['activo'] == true ? "[ON]" : "[OFF]"} ${p['nombre']} \$${precio.toInt()}/${p['unidad'] ?? 'und'} stk:${p['stock'] ?? 0}');
          }
        }
        if (ventas.docs.isNotEmpty) {
          double vendido = 0;
          int ok = 0, pend = 0, canc = 0;
          for (final d in ventas.docs) {
            final p = d.data() as Map<String, dynamic>;
            vendido += (p['precioTotal'] as num?)?.toDouble() ?? 0;
            final e = p['estado'] as String? ?? '';
            if (e == 'entregado') { ok++; } else if (e == 'cancelado') { canc++; } else { pend++; }
          }
          buf.writeln('VENTAS: \$${vendido.toInt()} | OK:$ok Pend:$pend Canc:$canc');
        }
      }

      if (favs.docs.isNotEmpty) {
        final ids = favs.docs.map((d) => d.id).toList();
        for (int i = 0; i < ids.length; i += 30) {
          final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
          final fp = await fs.collection('productos').where(FieldPath.documentId, whereIn: chunk).get();
          if (fp.docs.isNotEmpty) {
            buf.writeln('FAVORITOS: ${fp.docs.map((d) => d.data()['nombre']).join(', ')}');
          }
        }
      }

      return buf.toString();
    } catch (e) {
      debugPrint('User context error: $e');
      return '';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // INICIAR / REFRESCAR CHAT
  // ═══════════════════════════════════════════════════════════

  Future<void> startChat(String userId) async {
    try {
      _cachedUserId = userId;
      final ctx = await Future.wait([_getFullMarketContext(), _getFullUserContext(userId)]);
      _systemPrompt = '$_baseSystemPrompt\n\n${ctx[0]}\n\n${ctx[1]}';
      _chatHistory.clear();
      _lastContextRefresh = DateTime.now();
      debugPrint('AI: Ready — ${_systemPrompt.length} chars context | Groq+Gemini+OpenRouter');
    } catch (e) {
      debugPrint('AI init error: $e');
      _systemPrompt = _baseSystemPrompt;
      _chatHistory.clear();
    }
  }

  Future<void> _maybeRefreshContext() async {
    if (_lastContextRefresh == null) return;
    if (DateTime.now().difference(_lastContextRefresh!).inMinutes > 5) {
      try {
        final ctx = await Future.wait([_getFullMarketContext(), _getFullUserContext(_cachedUserId)]);
        _systemPrompt = '$_baseSystemPrompt\n\n${ctx[0]}\n\n${ctx[1]}';
        _lastContextRefresh = DateTime.now();
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════════════════════════════
  // GROQ — Streaming
  // ═══════════════════════════════════════════════════════════

  Future<String?> _callGroqStream(
    String model,
    List<Map<String, dynamic>> messages,
    void Function(String token)? onToken,
  ) async {
    try {
      final request = http.Request('POST', Uri.parse(_groqUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqApiKey',
      });
      request.body = jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': 1500,
        'temperature': 0.7,
        'stream': onToken != null,
      });

      final client = http.Client();
      try {
        final streamedResponse = await client.send(request).timeout(const Duration(seconds: 45));

        if (streamedResponse.statusCode != 200) {
          final body = await streamedResponse.stream.bytesToString();
          debugPrint('Groq error ($model): ${streamedResponse.statusCode} $body');
          return null;
        }

        if (onToken == null) {
          // Non-streaming
          final body = await streamedResponse.stream.bytesToString();
          final data = jsonDecode(body);
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            return choices[0]['message']?['content'] as String?;
          }
          return null;
        }

        // Streaming SSE
        final buffer = StringBuffer();
        final lineBuffer = StringBuffer();

        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          lineBuffer.write(chunk);
          final lines = lineBuffer.toString().split('\n');
          // Keep the last incomplete line in the buffer
          lineBuffer.clear();
          lineBuffer.write(lines.last);

          for (int i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (line.isEmpty || line == 'data: [DONE]') continue;
            if (!line.startsWith('data: ')) continue;

            try {
              final json = jsonDecode(line.substring(6));
              final delta = json['choices']?[0]?['delta']?['content'] as String?;
              if (delta != null && delta.isNotEmpty) {
                buffer.write(delta);
                onToken(delta);
              }
            } catch (_) {}
          }
        }

        final result = buffer.toString();
        return result.isNotEmpty ? result : null;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Groq stream error ($model): $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // GEMINI — Chat + Vision
  // ═══════════════════════════════════════════════════════════

  Future<String?> _callGeminiChat(List<Map<String, dynamic>> messages) async {
    try {
      final url = '$_geminiUrl/$_geminiModel:generateContent?key=$_geminiApiKey';
      final contents = <Map<String, dynamic>>[];
      String? systemText;

      for (final msg in messages) {
        if (msg['role'] == 'system') {
          systemText = msg['content'] as String?;
          continue;
        }
        contents.add({
          'role': msg['role'] == 'assistant' ? 'model' : 'user',
          'parts': [{'text': msg['content']}],
        });
      }

      final body = <String, dynamic>{
        'contents': contents,
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1500},
      };
      if (systemText != null) {
        body['systemInstruction'] = {'parts': [{'text': systemText}]};
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data['candidates']?[0]?['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] as String?;
        }
      }
      debugPrint('Gemini chat error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Gemini chat error: $e');
      return null;
    }
  }

  Future<String?> _callGeminiVision(String prompt, Uint8List imageBytes) async {
    try {
      final url = '$_geminiUrl/$_geminiModel:generateContent?key=$_geminiApiKey';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [
              {'text': prompt},
              {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Encode(imageBytes)}},
            ],
          }],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1500},
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = data['candidates']?[0]?['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) return parts[0]['text'] as String?;
      }
      debugPrint('Gemini vision error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Gemini vision error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // OPENROUTER — Fallback
  // ═══════════════════════════════════════════════════════════

  Future<String?> _callOpenRouter(String model, List<Map<String, dynamic>> messages) async {
    try {
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterKey',
        },
        body: jsonEncode({
          'model': model, 'messages': messages,
          'max_tokens': 1500, 'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']?['content'] as String?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('OpenRouter error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ENVIAR MENSAJE — Con streaming
  // ═══════════════════════════════════════════════════════════

  /// Envía un mensaje con streaming. [onToken] recibe cada fragmento de texto.
  /// Retorna la respuesta completa al final.
  Future<String> sendMessageStream(String message, {void Function(String token)? onToken}) async {
    await _maybeRefreshContext();
    _chatHistory.add({'role': 'user', 'content': message});

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
      ..._chatHistory,
    ];

    // 1. GROQ streaming (principal)
    debugPrint('AI: Groq streaming (Llama 3.3 70B)...');
    var text = await _callGroqStream(_groqModel, messages, onToken);
    if (text != null && text.isNotEmpty) {
      _addToHistory(text);
      return text;
    }

    // 2. GROQ fallback streaming
    debugPrint('AI: Groq fallback (Llama 3.1 8B)...');
    text = await _callGroqStream(_groqFallback, messages, onToken);
    if (text != null && text.isNotEmpty) {
      _addToHistory(text);
      return text;
    }

    // 3. Gemini (sin streaming, respuesta completa)
    debugPrint('AI: Gemini Flash...');
    text = await _callGeminiChat(messages);
    if (text != null && text.isNotEmpty) {
      onToken?.call(text);
      _addToHistory(text);
      return text;
    }

    // 4. OpenRouter fallbacks
    for (final model in _openRouterFallbacks) {
      debugPrint('AI: OpenRouter ($model)...');
      text = await _callOpenRouter(model, messages);
      if (text != null && text.isNotEmpty) {
        onToken?.call(text);
        _addToHistory(text);
        return text;
      }
    }

    _chatHistory.removeLast();
    return 'Los servidores están ocupados. Intenta en unos segundos.';
  }

  /// Envío sin streaming (compatibilidad)
  Future<String> sendMessage(String message) async {
    return sendMessageStream(message);
  }

  void _addToHistory(String text) {
    _chatHistory.add({'role': 'assistant', 'content': text});
    if (_chatHistory.length > 24) {
      _chatHistory.removeRange(0, _chatHistory.length - 24);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ANALIZAR IMAGEN — Gemini Vision → OpenRouter
  // ═══════════════════════════════════════════════════════════

  Future<String> analyzeProductImage(Uint8List imageBytes) async {
    final priceCtx = await _getPriceContext();

    final prompt = '''Eres el asistente de Urabá Market (marketplace local en Urabá, Colombia). Analiza esta foto.

$priceCtx

Responde en español:
1. **Producto identificado**: ¿Qué es?
2. **Categoría**: (Frutas, Verduras, Carnes, Pescados, Lácteos, Granos, Bebidas, Otros)
3. **Descripción para vender**: 2-3 líneas atractivas
4. **Precio sugerido**: basado en precios REALES del marketplace
5. **Tip**: Un consejo para vender mejor
Sé directo y usa datos reales.''';

    // Gemini Vision (mejor)
    var text = await _callGeminiVision(prompt, imageBytes);
    if (text != null && text.isNotEmpty) return text;

    // OpenRouter fallback
    try {
      final b64 = base64Encode(imageBytes);
      text = await _callOpenRouter('nvidia/nemotron-nano-12b-v2-vl:free', [
        {'role': 'user', 'content': [
          {'type': 'text', 'text': prompt},
          {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$b64'}},
        ]},
      ]);
      if (text != null && text.isNotEmpty) return text;
    } catch (_) {}

    return 'No pude analizar la imagen. Intenta con otra foto.';
  }

  Future<String> _getPriceContext() async {
    try {
      final prods = await FirebaseFirestore.instance
          .collection('productos').where('activo', isEqualTo: true).limit(100).get();
      final Map<String, List<double>> cp = {};
      for (final doc in prods.docs) {
        final d = doc.data();
        cp.putIfAbsent(d['categoria'] as String? ?? 'Otros', () => [])
            .add((d['precio'] as num?)?.toDouble() ?? 0);
      }
      final buf = StringBuffer('Precios del marketplace:\n');
      cp.forEach((c, p) {
        p.sort();
        final avg = p.reduce((a, b) => a + b) / p.length;
        buf.writeln('$c: \$${p.first.toInt()}-\$${p.last.toInt()} (prom \$${avg.toInt()})');
      });
      return buf.toString();
    } catch (_) {
      return '';
    }
  }

  /// Inyecta el resultado del análisis de imagen al historial del chat.
  /// Así cuando el usuario pregunte "como ves la foto", Groq ya tiene contexto.
  void injectImageContext(String imageAnalysis) {
    _chatHistory.add({
      'role': 'user',
      'content': '[SISTEMA: El usuario envió una foto y TÚ ya la analizaste visualmente. Este es TU análisis de lo que viste en la foto:]',
    });
    _chatHistory.add({
      'role': 'assistant',
      'content': 'He analizado la foto que me enviaste. Esto es lo que veo:\n\n$imageAnalysis',
    });
    // Keep history manageable
    if (_chatHistory.length > 24) {
      _chatHistory.removeRange(0, _chatHistory.length - 24);
    }
  }

  void resetChat() {
    _chatHistory.clear();
  }
}
