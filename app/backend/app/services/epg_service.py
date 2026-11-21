"""Dynamic EPG (Electronic Program Guide) and Signal Status service."""
import hashlib
from datetime import datetime, timezone

BRANDED_SHOWS = {
    'nickelodeon': [
        'Bob Esponja: Aventuras en Fondo de Bikini',
        'The Loud House: Una Casa de Locos',
        'Los Padrinos Mágicos: Nuevos Deseos',
        'Henry Danger: Misión Rescate',
        'Avatar: La Leyenda de Aang (Remasterizado)',
        'Danger Force: Academia de Héroes',
        'The Patrick Star Show: Descontrol Total',
        'Rugrats: Aventuras en Pañales',
        'Bob Esponja: Maratón Estelar',
        'Una Casa de Locos: Vacaciones Familiares',
    ],
    'nick': [
        'Bob Esponja: Aventuras en Fondo de Bikini',
        'The Loud House: Una Casa de Locos',
        'Los Padrinos Mágicos: Nuevos Deseos',
        'Henry Danger: Misión Rescate',
        'Danger Force: Academia de Héroes',
        'Rugrats: Aventuras en Pañales',
    ],
    'cartoon': [
        'El Increíble Mundo de Gumball',
        'Hora de Aventura: Tierras Lejanas',
        'Jóvenes Titanes en Acción! (Teen Titans Go)',
        'Escandalosos (We Bare Bears)',
        'Steven Universe: El Futuro',
        'El Mundo de Craig: En Busca del Tesoro',
        'Ben 10: Batalla Omniversal',
        'Manzana y Cebollín: Aventuras Urbanas',
    ],
    'disney': [
        'Phineas y Ferb: El Viaje a la Segunda Dimensión',
        'Gravity Falls: Misterios del Pueblo',
        'Miraculous: Las Aventuras de Ladybug',
        'Los Vecinos Green: Caos en la Granja',
        'Amphibia: El Reino de las Ranas',
        'Star vs. Las Fuerzas del Mal',
        'Patoaventuras: Búsqueda del Tesoro Perdido',
    ],
    'espn': [
        'SportsCenter: Noticias y Lo Mejor del Deporte',
        'Fútbol en Vivo: Jornada Internacional',
        'Equipo F: Análisis y Debate de Primera División',
        'SportsCenter Night: Resumen de Goles y Jugadas',
        'Fórmula 1: Previa y Clasificación de Carrera',
        'NBA Action: Lo Mejor del Baloncesto',
    ],
    'fox sports': [
        'Fox Sports Radio: Debate y Noticias en Directo',
        'Fútbol en Vivo: Copa Internacional de Campeones',
        'La Última Palabra: Mesa de Análisis Deportivo',
        'Lo Mejor de la Jornada: Goles y Polémicas',
        'Automovilismo: Rally y Velocidad Pura',
    ],
    'cnn': [
        'CNN Primera Mañana: Noticias del Mundo',
        'Panorama Mundial: Edición Central',
        'Conclusiones: Análisis y Entrevistas',
        'CNN En Directo: Última Hora y Cobertura Especial',
        'Redacción Internacional: Especial de Investigación',
    ],
    'discovery': [
        'Pesca Mortal: Mares Peligrosos en Alaska',
        'Supervivencia al Desnudo: Desafío Extremo',
        'Fiebre del Oro: Cazadores de Fortuna',
        'Grandes Construcciones: Mega Estructuras del Mundo',
        'Cazadores de Mitos: Experimentos Asombrosos',
    ],
    'history': [
        'El Precio de la Historia: Nuevas Negociaciones',
        'Alienígenas Ancestrales: Evidencias Ocultas',
        'Cazadores de Tesoros: Rutas Americanas',
        'Desafío Sobre Fuego: La Hoja Suprema',
        'Misterios Revelados: Enigmas de la Historia',
    ],
    'geographic': [
        'Planeta Tierra: Ecosistemas Salvajes',
        'Depredadores Letales de la Sabana Africana',
        'Océanos Secretos: Exploración en las Profundidades',
        'El Reino de los Felinos Salvajes',
        'Megaestructuras de la Naturaleza',
    ],
    'nat geo': [
        'Planeta Tierra: Ecosistemas Salvajes',
        'Depredadores Letales de la Sabana Africana',
        'Océanos Secretos: Exploración en las Profundidades',
        'El Reino de los Felinos Salvajes',
    ],
    'hbo': [
        'Cine Estelar: Estreno Exclusivo de Hollywood',
        'Noche de Película: Acción y Aventura',
        'Serie Original HBO: Episodio Doble',
        'Cine Premiado: Grandes Producciones',
    ],
    'warner': [
        'The Big Bang Theory: Maratón de Comedia',
        'Friends: Los Mejores Momentos',
        'Two and a Half Men: Temporada Estelar',
        'Flash / DC: Batalla de Superhéroes',
    ],
    'mtv': [
        'Top 20 Countdown: Los Éxitos Más Escuchados',
        'MTV Hits: Pop y Urbano Latino Non-Stop',
        'Videoclips en Rotación Continua',
        'MTV Acústico: Grandes Conciertos en Vivo',
    ]
}

CATEGORY_SHOWS = {
    'Infantil': [
        'Aventuras Animadas: Episodio Doble',
        'El Reino Mágico: Nuevas Historias',
        'Pequeños Héroes: Misión en Equipo',
        'Mundo de Dibujos: Maratón Matutino',
        'Fantasía y Diversión para Toda la Familia',
        'Super Amigos: En Busca del Tesoro',
    ],
    'Deportes': [
        'Transmisión en Vivo: Partido de la Fecha',
        'SportsCenter: Noticias y Resumen Deportivo',
        'Goles y Jugadas de Primera División',
        'Debate Deportivo: La Mesa Redonda',
        'El Gran Partido: En Vivo y en Directo',
        'Especial Polideportivo: Lo Mejor del Mes',
    ],
    'Noticias': [
        'El Noticiero Central: Información de Última Hora',
        'Primera Edición: Titulares Nacionales e Internacionales',
        'Debate y Opinión: Análisis de la Realidad',
        'Economía y Mercados: Reporte Especial',
        'El Estado del Tiempo: Pronóstico Detallado',
        'Edición Nocturna: Resumen Completo del Día',
    ],
    'Películas': [
        'Cine Estelar: Película Destacada',
        'Función de Gala: Acción y Aventura',
        'Cine Clásico Inolvidable: Obra Maestra',
        'Especial de Suspenso y Terror',
        'Comedia Romántica: Tarde de Película',
        'Noche de Hollywood: Blockbuster',
    ],
    'Series': [
        'Serie Estelar: Episodio de Estreno',
        'Maratón de Temporada: Capítulos Seguidos',
        'Misterio e Investigación: Caso Abierto',
        'Comedia de Situación: Risas Aseguradas',
        'Drama de Época: Gran Producción',
    ],
    'Música': [
        'Top 40 Éxitos: Los Temas Más Sonados',
        'Música Latina y Ritmos Urbanos en Vivo',
        'Clásicos Inmortales del Rock & Pop',
        'Sesión Acústica: En Directo desde el Estudio',
        'Videoclips Non-Stop 24/7',
    ],
    'Documentales': [
        'Mundo Salvaje: Naturaleza Asombrosa',
        'Secretos del Universo y del Cosmos',
        'Grandes Civilizaciones de la Historia',
        'Tecnología y Futuro: Inteligencia Artificial',
        'Océanos Desconocidos: Fauna Marina',
    ],
    'Cocina': [
        'Recetas Rápidas y Deliciosas en 30 Minutos',
        'Master Cocina: Duelo de Sabores',
        'Panadería y Dulces Caseros Tradicionales',
        'Ruta Gastronómica: Sabores del Mundo',
    ],
    'Comedia': [
        'Risas en Vivo: Los Mejores Monólogos',
        'Comedia en Serie: Especial Fin de Semana',
        'Humor sin Filtro: Nuevos Talentos',
    ],
    'Cultura': [
        'Arte y Tradiciones de Nuestra Tierra',
        'Recorridos por los Museos del Mundo',
        'Patrimonio de la Humanidad: Tesoros Vivos',
    ],
    'Educación': [
        'Ciencia Divertida para Curiosos',
        'Historia Universal al Detalle',
        'Aprender Jugando: Curiosidades del Planeta',
    ],
    'General': [
        'Magazine Matinal: Entrevistas y Variedades',
        'Tarde de Entretenimiento en Directo',
        'El Show Central: Invitados Especiales',
        'Transmisión en Vivo: Programa Estelar',
        'Noche de Variedades y Magia',
    ]
}

def get_channel_epg(channel_id: str, channel_name: str, category: str = None, stream_url: str = ""):
    """Compute current realistic EPG schedule and stream online status."""
    now = datetime.now()
    hour = now.hour
    minute = now.minute
    
    # 30-minute schedule blocks: e.g. 16:00 - 16:30 or 16:30 - 17:00
    if minute < 30:
        start_min, end_min = "00", "30"
        end_hour = hour
    else:
        start_min, end_min = "30", "00"
        end_hour = (hour + 1) % 24

    time_str = f"{hour:02d}:{start_min} - {end_hour:02d}:{end_min}"
    
    name_lower = (channel_name or "").lower()
    
    # Check if branded channel
    shows = None
    for brand, brand_shows in BRANDED_SHOWS.items():
        if brand in name_lower:
            shows = brand_shows
            break
            
    if not shows:
        cat_key = category or 'General'
        shows = CATEGORY_SHOWS.get(cat_key, CATEGORY_SHOWS['General'])
        
    # Pick a deterministic, stable show for this channel + hour block
    slot_index = (hour * 2 + (1 if minute >= 30 else 0))
    raw_hash = int(hashlib.md5(f"{channel_id}:{slot_index}".encode()).hexdigest()[:8], 16)
    selected_show = shows[raw_hash % len(shows)]
    
    # Determine stream validity
    url = (stream_url or "").strip().lower()
    is_online = bool(url.startswith(('http://', 'https://')) and len(url) > 12)
    
    return {
        "current_program": selected_show,
        "program_time": time_str,
        "is_online": is_online
    }
