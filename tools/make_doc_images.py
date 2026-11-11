"""Documentation images for the README, the wiki and the Steam Workshop page.

    python tools/make_doc_images.py [LANG ...]      (default: all languages)

Writes docs/images/diagrams/<name>_<lang>.png: diagram (how it works), production (charts), recipe_book (recipes,
640 px wide for the Steam page), equipment (device board).
Only Pillow is needed. Figures come from the mod's model (docs/specifications-techniques.md); the solar day is the
sine curve of LW_Physics.solarCurve with the day lengths that give the documented 0.94 / 0.60 kWh.
Item names come from the game's translations (vanilla items) and the mod's translations (mod items).
"""
import json
import math
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "images", "diagrams")
ICONS = os.path.join(ROOT, "docs", "images", "icons")
MODS = os.path.join(ROOT, "Contents", "mods")
BASE_MOD = os.path.join(MODS, "batman_LiveWire", "42.21", "media")
EXT_MOD = os.path.join(MODS, "batman_LiveWireExtended", "42.21", "media")
# Recipe scripts: every craftRecipe block of both mods is read from here (no hand-written recipe table).
BASE_RECIPES = os.path.join(BASE_MOD, "scripts", "LiveWire_recipes.txt")
EXT_RECIPES = os.path.join(EXT_MOD, "scripts", "LiveWireExtended_recipes.txt")
MOD_TR = os.path.join(BASE_MOD, "lua", "shared", "Translate")
EXT_TR = os.path.join(EXT_MOD, "lua", "shared", "Translate")
GAME_MEDIA = os.environ.get("PZ_MEDIA", r"D:\SteamLibrary\steamapps\common\ProjectZomboid\media")
GAME_TR = os.environ.get("PZ_TRANSLATE", os.path.join(GAME_MEDIA, "lua", "shared", "Translate"))
FONTS = os.environ.get("FONTS_DIR", r"C:\Windows\Fonts")
LANGS = ["EN", "FR", "DE", "ES", "PTBR", "PT", "RU", "CN", "JP", "KO", "TR"]
# Languages written with a decimal comma.
DECIMAL_COMMA = ("FR", "DE", "ES", "PTBR", "PT", "RU", "TR")

BG = (251, 247, 239)
CARD = (255, 255, 255)
LINE = (214, 207, 196)
INK = (31, 42, 51)
MUTED = (107, 114, 128)
ACCENT = (184, 98, 42)
ACCENT_BG = (243, 225, 211)
GREEN = (62, 154, 85)
GREEN_BG = (227, 241, 228)
BLUE = (46, 108, 176)
GREY = (150, 150, 150)

FONT_FILES = {
    "CN": ("msyh.ttc", "msyhbd.ttc"),
    "JP": ("YuGothM.ttc", "YuGothB.ttc"),
    "KO": ("malgun.ttf", "malgunbd.ttf"),
}


def font(lang, size, bold=False):
    reg, bld = FONT_FILES.get(lang, ("segoeui.ttf", "segoeuib.ttf"))
    return ImageFont.truetype(os.path.join(FONTS, bld if bold else reg), size)


# --- Labels -------------------------------------------------------------------------------------
L = {
    "EN": {
        "sources": "SOURCES", "solar": "Solar panel · 100 W", "wind": "Wind turbine · 400 W",
        "water": "Water wheel · 120 W", "src_note": "unlimited number,\nup to 12 tiles from the inverter",
        "wire": "electric wire", "wire_cost": "1 wire / 4 tiles", "inverter": "INVERTER",
        "inv_main": "1,500 W max · 20 W idle", "inv_note": "one per network · indoor placement\nno toxicity",
        "house_power": "house power", "house": "HOUSE", "house_main": "Fridges, lights,\nstoves, TV, radios…",
        "house_note": "radius 20 tiles, ±3 floors,\ncentred on the inverter,\nno wiring per appliance",
        "store": "stores / returns", "bank": "POWER BANK (optional)", "bank_note": "4 batteries · charge efficiency 0.90",
        "c_solar": "Solar panel over one day (new panel)", "summer": "Summer, clear sky", "winter": "Winter, clear sky",
        "overcast": "Summer, overcast", "hour": "Hour", "c_wind": "Wind turbine power vs wind speed",
        "wind_axis": "Wind (km/h)", "brake": "brake above 85 km/h", "c_daily": "Energy per day vs a typical house",
        "need": "need 3.8 kWh/day (game values profile)", "s_summer": "Summer", "s_winter": "Winter",
        "g1": "4 solar panels", "g2": "6 panels\n+ 1 wind turbine", "g3": "1 water wheel\n+ 2 panels",
        "recipes": "RECIPES", "no_level": "no level", "tools": "Tools (kept)", "level": "%s %d",
        "any_car_battery": "Car Battery (any)",
    },
    "FR": {
        "sources": "SOURCES", "solar": "Panneau solaire · 100 W", "wind": "Éolienne · 400 W",
        "water": "Roue à aubes · 120 W", "src_note": "nombre illimité,\njusqu'à 12 cases de l'onduleur",
        "wire": "fil électrique", "wire_cost": "1 fil / 4 cases", "inverter": "ONDULEUR",
        "inv_main": "1 500 W max · 20 W à vide", "inv_note": "un par réseau · pose intérieure\naucune toxicité",
        "house_power": "courant de la maison", "house": "MAISON",
        "house_main": "Réfrigérateurs, lumières,\ncuisinières, TV, radios…",
        "house_note": "rayon 20 cases, ±3 étages,\ncentré sur l'onduleur,\naucun câblage par appareil",
        "store": "stocke / restitue", "bank": "POWERBANK (facultatif)", "bank_note": "4 batteries · rendement de charge 0,90",
        "c_solar": "Panneau solaire sur une journée (panneau neuf)", "summer": "Été, ciel dégagé",
        "winter": "Hiver, ciel dégagé", "overcast": "Été, ciel couvert", "hour": "Heure",
        "c_wind": "Puissance de l'éolienne selon le vent", "wind_axis": "Vent (km/h)", "brake": "frein au-delà de 85 km/h",
        "c_daily": "Énergie par jour face à une maison type",
        "need": "besoin 3,8 kWh/jour (profil valeurs du jeu)", "s_summer": "Été", "s_winter": "Hiver",
        "g1": "4 panneaux solaires", "g2": "6 panneaux\n+ 1 éolienne", "g3": "1 roue à aubes\n+ 2 panneaux",
        "recipes": "RECETTES", "no_level": "sans niveau", "tools": "Outils (conservés)", "level": "%s %d",
        "any_car_battery": "Batterie de voiture (toutes)",
    },
    "DE": {
        "sources": "QUELLEN", "solar": "Solarmodul · 100 W", "wind": "Windrad · 400 W",
        "water": "Wasserrad · 120 W", "src_note": "beliebig viele,\nbis 12 Felder vom Wechselrichter",
        "wire": "Elektrokabel", "wire_cost": "1 Kabel / 4 Felder", "inverter": "WECHSELRICHTER",
        "inv_main": "max. 1.500 W · 20 W Leerlauf", "inv_note": "einer pro Netz · im Haus aufstellbar\nnicht giftig",
        "house_power": "Hausstrom", "house": "HAUS", "house_main": "Kühlschränke, Lampen,\nHerde, TV, Radios…",
        "house_note": "Radius 20 Felder, ±3 Etagen,\num den Wechselrichter,\nkeine Verkabelung pro Gerät",
        "store": "speichert / gibt ab", "bank": "POWERBANK (optional)", "bank_note": "4 Batterien · Ladewirkungsgrad 0,90",
        "c_solar": "Solarmodul über einen Tag (neues Modul)", "summer": "Sommer, klarer Himmel",
        "winter": "Winter, klarer Himmel", "overcast": "Sommer, bedeckt", "hour": "Uhrzeit",
        "c_wind": "Leistung des Windrads nach Windstärke", "wind_axis": "Wind (km/h)", "brake": "Bremse über 85 km/h",
        "c_daily": "Energie pro Tag für ein typisches Haus",
        "need": "Bedarf 3,8 kWh/Tag (Profil Spielwerte)", "s_summer": "Sommer", "s_winter": "Winter",
        "g1": "4 Solarmodule", "g2": "6 Module\n+ 1 Windrad", "g3": "1 Wasserrad\n+ 2 Module",
        "recipes": "REZEPTE", "no_level": "ohne Stufe", "tools": "Werkzeuge (bleiben)", "level": "%s %d",
        "any_car_battery": "Autobatterie (beliebig)",
    },
    "ES": {
        "sources": "FUENTES", "solar": "Panel solar · 100 W", "wind": "Aerogenerador · 400 W",
        "water": "Rueda hidráulica · 120 W", "src_note": "número ilimitado,\nhasta 12 casillas del inversor",
        "wire": "cable eléctrico", "wire_cost": "1 cable / 4 casillas", "inverter": "INVERSOR",
        "inv_main": "1.500 W máx. · 20 W en reposo", "inv_note": "uno por red · se instala dentro\nno es tóxico",
        "house_power": "corriente de la casa", "house": "CASA",
        "house_main": "Neveras, luces,\ncocinas, TV, radios…",
        "house_note": "radio de 20 casillas, ±3 plantas,\ncentrado en el inversor,\nsin cableado por aparato",
        "store": "almacena / devuelve", "bank": "BANCO DE BATERÍAS (opcional)", "bank_note": "4 baterías · rendimiento de carga 0,90",
        "c_solar": "Panel solar durante un día (panel nuevo)", "summer": "Verano, cielo despejado",
        "winter": "Invierno, cielo despejado", "overcast": "Verano, nublado", "hour": "Hora",
        "c_wind": "Potencia del aerogenerador según el viento", "wind_axis": "Viento (km/h)",
        "brake": "freno por encima de 85 km/h", "c_daily": "Energía por día frente a una casa típica",
        "need": "necesidad 3,8 kWh/día (perfil valores del juego)", "s_summer": "Verano", "s_winter": "Invierno",
        "g1": "4 paneles solares", "g2": "6 paneles\n+ 1 aerogenerador", "g3": "1 rueda hidráulica\n+ 2 paneles",
        "recipes": "RECETAS", "no_level": "sin nivel", "tools": "Herramientas (se conservan)", "level": "%s %d",
        "any_car_battery": "Batería de coche (cualquiera)",
    },
    "PTBR": {
        "sources": "FONTES", "solar": "Painel solar · 100 W", "wind": "Turbina eólica · 400 W",
        "water": "Roda d'água · 120 W", "src_note": "quantidade ilimitada,\naté 12 quadrados do inversor",
        "wire": "fio elétrico", "wire_cost": "1 fio / 4 quadrados", "inverter": "INVERSOR",
        "inv_main": "1.500 W máx. · 20 W em repouso", "inv_note": "um por rede · instalação interna\nsem toxicidade",
        "house_power": "energia da casa", "house": "CASA", "house_main": "Geladeiras, luzes,\nfogões, TV, rádios…",
        "house_note": "raio de 20 quadrados, ±3 andares,\ncentrado no inversor,\nsem fiação por aparelho",
        "store": "armazena / devolve", "bank": "BANCO DE BATERIAS (opcional)", "bank_note": "4 baterias · eficiência de carga 0,90",
        "c_solar": "Painel solar ao longo de um dia (painel novo)", "summer": "Verão, céu limpo",
        "winter": "Inverno, céu limpo", "overcast": "Verão, nublado", "hour": "Hora",
        "c_wind": "Potência da turbina eólica conforme o vento", "wind_axis": "Vento (km/h)",
        "brake": "freio acima de 85 km/h", "c_daily": "Energia por dia para uma casa típica",
        "need": "consumo 3,8 kWh/dia (perfil valores do jogo)", "s_summer": "Verão", "s_winter": "Inverno",
        "g1": "4 painéis solares", "g2": "6 painéis\n+ 1 turbina eólica", "g3": "1 roda d'água\n+ 2 painéis",
        "recipes": "RECEITAS", "no_level": "sem nível", "tools": "Ferramentas (mantidas)", "level": "%s %d",
        "any_car_battery": "Bateria de carro (qualquer)",
    },
    "PT": {
        "sources": "FONTES", "solar": "Painel solar · 100 W", "wind": "Turbina eólica · 400 W",
        "water": "Roda de água · 120 W", "src_note": "quantidade ilimitada,\naté 12 quadrículas do inversor",
        "wire": "fio eléctrico", "wire_cost": "1 fio / 4 quadrículas", "inverter": "INVERSOR",
        "inv_main": "1500 W máx. · 20 W em vazio", "inv_note": "um por rede · instalação interior\nsem toxicidade",
        "house_power": "energia da casa", "house": "CASA", "house_main": "Frigoríficos, luzes,\nfogões, TV, rádios…",
        "house_note": "raio de 20 quadrículas, ±3 pisos,\ncentrado no inversor,\nsem cablagem por aparelho",
        "store": "armazena / devolve", "bank": "BANCO DE BATERIAS (opcional)", "bank_note": "4 baterias · rendimento de carga 0,90",
        "c_solar": "Painel solar ao longo de um dia (painel novo)", "summer": "Verão, céu limpo",
        "winter": "Inverno, céu limpo", "overcast": "Verão, encoberto", "hour": "Hora",
        "c_wind": "Potência da turbina eólica consoante o vento", "wind_axis": "Vento (km/h)",
        "brake": "travão acima de 85 km/h", "c_daily": "Energia por dia para uma casa típica",
        "need": "consumo 3,8 kWh/dia (perfil valores do jogo)", "s_summer": "Verão", "s_winter": "Inverno",
        "g1": "4 painéis solares", "g2": "6 painéis\n+ 1 turbina eólica", "g3": "1 roda de água\n+ 2 painéis",
        "recipes": "RECEITAS", "no_level": "sem nível", "tools": "Ferramentas (mantidas)", "level": "%s %d",
        "any_car_battery": "Bateria de carro (qualquer)",
    },
    "RU": {
        "sources": "ИСТОЧНИКИ", "solar": "Солнечная панель · 100 Вт", "wind": "Ветряк · 400 Вт",
        "water": "Водяное колесо · 120 Вт", "src_note": "без ограничения числа,\nдо 12 клеток от инвертора",
        "wire": "электропровод", "wire_cost": "1 провод / 4 клетки", "inverter": "ИНВЕРТОР",
        "inv_main": "макс. 1500 Вт · 20 Вт простой", "inv_note": "один на сеть · можно в доме\nне токсичен",
        "house_power": "ток в дом", "house": "ДОМ", "house_main": "Холодильники, свет,\nплиты, ТВ, радио…",
        "house_note": "радиус 20 клеток, ±3 этажа,\nвокруг инвертора,\nбез проводки к приборам",
        "store": "хранит / отдаёт", "bank": "БЛОК АККУМУЛЯТОРОВ (по желанию)", "bank_note": "4 батареи · КПД заряда 0,90",
        "c_solar": "Солнечная панель за сутки (новая панель)", "summer": "Лето, ясно", "winter": "Зима, ясно",
        "overcast": "Лето, пасмурно", "hour": "Час", "c_wind": "Мощность ветряка в зависимости от ветра",
        "wind_axis": "Ветер (км/ч)", "brake": "тормоз выше 85 км/ч", "c_daily": "Энергия в сутки для типичного дома",
        "need": "нужно 3,8 кВт·ч/сутки (профиль «значения игры»)", "s_summer": "Лето", "s_winter": "Зима",
        "g1": "4 солнечные\nпанели", "g2": "6 панелей\n+ 1 ветряк", "g3": "1 водяное колесо\n+ 2 панели",
        "recipes": "РЕЦЕПТЫ", "no_level": "без уровня", "tools": "Инструменты (остаются)", "level": "%s %d",
        "any_car_battery": "Автомобильный аккумулятор (любой)",
    },
    "CN": {
        "sources": "电源", "solar": "太阳能板 · 100 W", "wind": "风力发电机 · 400 W",
        "water": "水车 · 120 W", "src_note": "数量不限，\n距逆变器最多 12 格",
        "wire": "电线", "wire_cost": "每 4 格 1 根电线", "inverter": "逆变器",
        "inv_main": "最大 1500 W · 待机 20 W", "inv_note": "每个电网一台 · 可放室内\n无毒",
        "house_power": "房屋供电", "house": "房屋", "house_main": "冰箱、灯、\n炉灶、电视、收音机…",
        "house_note": "半径 20 格，上下 3 层，\n以逆变器为中心，\n电器无需单独接线",
        "store": "储存 / 释放", "bank": "电池组（可选）", "bank_note": "4 块电池 · 充电效率 0.90",
        "c_solar": "太阳能板一天的输出（新板）", "summer": "夏季，晴天", "winter": "冬季，晴天",
        "overcast": "夏季，阴天", "hour": "时", "c_wind": "风力发电机功率与风速",
        "wind_axis": "风速 (km/h)", "brake": "超过 85 km/h 制动", "c_daily": "每日发电量与典型房屋需求",
        "need": "需求 3.8 kWh/天（游戏数值方案）", "s_summer": "夏季", "s_winter": "冬季",
        "g1": "4 块太阳能板", "g2": "6 块板\n+ 1 台风力发电机", "g3": "1 个水车\n+ 2 块板",
        "recipes": "配方", "no_level": "无等级", "tools": "工具（保留）", "level": "%s %d",
        "any_car_battery": "汽车电池（任意）",
    },
    "JP": {
        "sources": "電源", "solar": "ソーラーパネル · 100 W", "wind": "風力タービン · 400 W",
        "water": "水車 · 120 W", "src_note": "数は無制限、\nインバーターから12マスまで",
        "wire": "電線", "wire_cost": "4マスごとに電線1本", "inverter": "インバーター",
        "inv_main": "最大 1500 W · 待機 20 W", "inv_note": "1ネットワークに1台 · 屋内設置可\n毒性なし",
        "house_power": "家への電力", "house": "家", "house_main": "冷蔵庫、照明、\nコンロ、テレビ、ラジオ…",
        "house_note": "半径20マス、上下3階、\nインバーター中心、\n家電ごとの配線不要",
        "store": "蓄電 / 放電", "bank": "パワーバンク（任意）", "bank_note": "バッテリー4個 · 充電効率 0.90",
        "c_solar": "ソーラーパネルの1日の出力（新品）", "summer": "夏・晴れ", "winter": "冬・晴れ",
        "overcast": "夏・曇り", "hour": "時", "c_wind": "風速による風力タービンの出力",
        "wind_axis": "風速 (km/h)", "brake": "85 km/h 超でブレーキ", "c_daily": "1日の発電量と標準的な家の消費",
        "need": "必要量 3.8 kWh/日（ゲームの値）", "s_summer": "夏", "s_winter": "冬",
        "g1": "ソーラー\nパネル4枚", "g2": "パネル6枚\n+ 風力タービン1基", "g3": "水車1基\n+ パネル2枚",
        "recipes": "レシピ", "no_level": "レベル不要", "tools": "道具（消費しない）", "level": "%s %d",
        "any_car_battery": "車のバッテリー（種類問わず）",
    },
    "KO": {
        "sources": "전원", "solar": "태양광 패널 · 100 W", "wind": "풍력 터빈 · 400 W",
        "water": "물레방아 · 120 W", "src_note": "개수 제한 없음,\n인버터에서 최대 12칸",
        "wire": "전선", "wire_cost": "4칸마다 전선 1개", "inverter": "인버터",
        "inv_main": "최대 1,500 W · 대기 20 W", "inv_note": "네트워크당 1대 · 실내 설치 가능\n독성 없음",
        "house_power": "집 전력", "house": "집", "house_main": "냉장고, 조명,\n레인지, TV, 라디오…",
        "house_note": "반경 20칸, 위아래 3층,\n인버터 중심,\n가전별 배선 불필요",
        "store": "저장 / 공급", "bank": "파워뱅크 (선택)", "bank_note": "배터리 4개 · 충전 효율 0.90",
        "c_solar": "하루 동안의 태양광 패널 출력 (새 패널)", "summer": "여름, 맑음", "winter": "겨울, 맑음",
        "overcast": "여름, 흐림", "hour": "시", "c_wind": "풍속에 따른 풍력 터빈 출력",
        "wind_axis": "풍속 (km/h)", "brake": "85 km/h 초과 시 제동", "c_daily": "하루 발전량과 일반 가정 소비",
        "need": "필요량 3.8 kWh/일 (게임 값 프로필)", "s_summer": "여름", "s_winter": "겨울",
        "g1": "태양광 패널 4개", "g2": "패널 6개\n+ 풍력 터빈 1대", "g3": "물레방아 1개\n+ 패널 2개",
        "recipes": "레시피", "no_level": "레벨 없음", "tools": "도구 (유지)", "level": "%s %d",
        "any_car_battery": "자동차 배터리 (아무거나)",
    },
    "TR": {
        "sources": "KAYNAKLAR", "solar": "Güneş paneli · 100 W", "wind": "Rüzgâr türbini · 400 W",
        "water": "Su çarkı · 120 W", "src_note": "sınırsız sayıda,\ninvertere en fazla 12 kare",
        "wire": "elektrik kablosu", "wire_cost": "4 karede 1 kablo", "inverter": "İNVERTER",
        "inv_main": "en fazla 1.500 W · boşta 20 W", "inv_note": "ağ başına bir · iç mekâna kurulur\nzehirsiz",
        "house_power": "ev elektriği", "house": "EV", "house_main": "Buzdolapları, ışıklar,\nocaklar, TV, radyolar…",
        "house_note": "20 kare yarıçap, ±3 kat,\ninverter merkezli,\ncihaz başına kablo yok",
        "store": "depolar / geri verir", "bank": "GÜÇ BANKASI (isteğe bağlı)", "bank_note": "4 akü · şarj verimi 0,90",
        "c_solar": "Bir günde güneş paneli (yeni panel)", "summer": "Yaz, açık hava",
        "winter": "Kış, açık hava", "overcast": "Yaz, bulutlu", "hour": "Saat",
        "c_wind": "Rüzgâra göre türbin gücü", "wind_axis": "Rüzgâr (km/sa)", "brake": "85 km/sa üstünde fren",
        "c_daily": "Tipik bir eve karşı günlük enerji",
        "need": "ihtiyaç 3,8 kWh/gün (oyun değerleri profili)", "s_summer": "Yaz", "s_winter": "Kış",
        "g1": "4 güneş paneli", "g2": "6 panel\n+ 1 rüzgâr türbini", "g3": "1 su çarkı\n+ 2 panel",
        "recipes": "TARİFLER", "no_level": "seviye yok", "tools": "Aletler (kalır)", "level": "%s %d",
        "any_car_battery": "Araba aküsü (herhangi biri)",
    },
}

# Strings added for LiveWire 2.0.0 (extended recipe book, dismantling card, Extended board, inverter coupling).
EXTRA_L = {
    "EN": {"inv_note": "up to 4 per network (coupling kit)\nindoor placement · no toxicity",
           "dis_title": "DISMANTLING", "dis_all": "Screwdriver for all %d recipes · no level",
           "dis_extra": "+ %s: %s", "fig_zone": "zone up to 16 × 16 tiles", "fig_modules": "%d modules",
           "fig_night": "on at night only", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "FR": {"inv_note": "jusqu'à 4 par réseau (kit de couplage)\npose intérieure · aucune toxicité",
           "dis_title": "DÉMONTAGE", "dis_all": "Tournevis pour les %d recettes · sans niveau",
           "dis_extra": "+ %s : %s", "fig_zone": "zone jusqu'à 16 × 16 cases", "fig_modules": "%d modules",
           "fig_night": "allumé la nuit seulement", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "DE": {"inv_note": "bis zu 4 pro Netz (Kopplungsset)\nim Haus aufstellbar · nicht giftig",
           "dis_title": "ZERLEGEN", "dis_all": "Schraubendreher für alle %d Rezepte · ohne Stufe",
           "dis_extra": "+ %s: %s", "fig_zone": "Zone bis 16 × 16 Felder", "fig_modules": "%d Module",
           "fig_night": "nur nachts an", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "ES": {"inv_note": "hasta 4 por red (kit de acoplamiento)\ninterior · no es tóxico",
           "dis_title": "DESMONTAJE", "dis_all": "Destornillador para las %d recetas · sin nivel",
           "dis_extra": "+ %s: %s", "fig_zone": "zona hasta 16 × 16 casillas", "fig_modules": "%d módulos",
           "fig_night": "encendido solo de noche", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "PTBR": {"inv_note": "até 4 por rede (kit de acoplamento)\ninstalação interna · sem toxicidade",
             "dis_title": "DESMONTAGEM", "dis_all": "Chave de fenda para as %d receitas · sem nível",
             "dis_extra": "+ %s: %s", "fig_zone": "zona até 16 × 16 quadrados", "fig_modules": "%d módulos",
             "fig_night": "ligado só à noite", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "PT": {"inv_note": "até 4 por rede (kit de acoplamento)\ninstalação interior · sem toxicidade",
           "dis_title": "DESMONTAGEM", "dis_all": "Chave de parafusos para as %d receitas · sem nível",
           "dis_extra": "+ %s: %s", "fig_zone": "zona até 16 × 16 quadrículas", "fig_modules": "%d módulos",
           "fig_night": "ligado só de noite", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "RU": {"inv_note": "до 4 на сеть (комплект связки)\nможно в доме · не токсичен",
           "dis_title": "РАЗБОРКА", "dis_all": "Отвёртка для всех %d рецептов · без уровня",
           "dis_extra": "+ %s: %s", "fig_zone": "зона до 16 × 16 клеток", "fig_modules": "модулей: %d",
           "fig_night": "только ночью", "fig_amp": "%d A · %d %s", "w_unit": "Вт"},
    "CN": {"inv_note": "每个电网最多 4 台（耦合套件）\n可放室内 · 无毒",
           "dis_title": "拆解", "dis_all": "%d 个配方都需要螺丝刀 · 无等级",
           "dis_extra": "+ %s：%s", "fig_zone": "区域最大 16 × 16 格", "fig_modules": "%d 个模块",
           "fig_night": "仅夜间导通", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "JP": {"inv_note": "1ネットワークに最大4台（連結キット）\n屋内設置可 · 毒性なし",
           "dis_title": "分解", "dis_all": "%d件すべてドライバーが必要 · レベル不要",
           "dis_extra": "+ %s：%s", "fig_zone": "範囲 最大 16 × 16 マス", "fig_modules": "%dモジュール",
           "fig_night": "夜間のみ通電", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "KO": {"inv_note": "네트워크당 최대 4대 (연결 키트)\n실내 설치 가능 · 독성 없음",
           "dis_title": "분해", "dis_all": "%d개 레시피 모두 드라이버 필요 · 레벨 없음",
           "dis_extra": "+ %s: %s", "fig_zone": "구역 최대 16 × 16칸", "fig_modules": "%d 모듈",
           "fig_night": "밤에만 통전", "fig_amp": "%d A · %d %s", "w_unit": "W"},
    "TR": {"inv_note": "ağ başına en fazla 4 (bağlama kiti)\niç mekâna kurulur · zehirsiz",
           "dis_title": "SÖKME", "dis_all": "%d tarifin hepsi için tornavida · seviye yok",
           "dis_extra": "+ %s: %s", "fig_zone": "en fazla 16 × 16 karelik alan", "fig_modules": "%d modül",
           "fig_night": "yalnızca gece açık", "fig_amp": "%d A · %d %s", "w_unit": "W"},
}
# Base breaker on the equipment board: an overload trips it instead of the inverter, which is not damaged
# (LW_Simulation.tripOverload); its threshold is the network capacity, not a fixed wattage.
BREAKER_FIG = {
    "EN": "protects the inverter", "FR": "protège l'onduleur", "DE": "schützt den Wechselrichter",
    "ES": "protege el inversor", "PTBR": "protege o inversor", "PT": "protege o inversor",
    "RU": "защищает инвертор", "CN": "保护逆变器", "JP": "インバーターを保護", "KO": "인버터 보호",
    "TR": "inverteri korur",
}
for _lang in L:
    L[_lang].update(EXTRA_L[_lang])

# --- Drawing helpers ----------------------------------------------------------------------------


def text(d, xy, s, f, fill=INK, anchor="la", spacing=4, align="left"):
    d.multiline_text(xy, s, font=f, fill=fill, anchor=anchor, spacing=spacing, align=align)


def tsize(d, s, f, spacing=4):
    b = d.multiline_textbbox((0, 0), s, font=f, spacing=spacing)
    return b[2] - b[0], b[3] - b[1]


def fit(d, s, lang, size, width, bold=False):
    """Largest font up to size whose widest line fits in width."""
    while size > 10:
        f = font(lang, size, bold)
        if tsize(d, s, f)[0] <= width:
            return f
        size -= 1
    return font(lang, size, bold)


def arrow(d, x0, y0, x1, y1, w=5, head=16):
    d.line((x0, y0, x1 - (head if x1 > x0 else 0), y1), fill=ACCENT, width=w)
    if x1 > x0:
        d.polygon([(x1, y1), (x1 - head, y1 - head * 0.6), (x1 - head, y1 + head * 0.6)], fill=ACCENT)


def caps(s, lang):
    """Capitals with the Turkish dotted / dotless i (i -> İ, ı -> I)."""
    if lang == "TR":
        s = s.replace("i", "İ").replace("ı", "I")
    return s.upper()


def save(im, name, lang):
    os.makedirs(OUT, exist_ok=True)
    p = os.path.join(OUT, "%s_%s.png" % (name, lang.lower()))
    im.save(p, optimize=True)
    print("wrote", os.path.relpath(p, ROOT), im.size)


# --- 1. Diagram ---------------------------------------------------------------------------------

BREAKER_NOTES = {
    "EN": "Overload protection\nLighting / equipment\nMain switch",
    "FR": "Protection surcharge\nÉclairage / équipements\nCoupure principale",
    "DE": "Überlastschutz\nLicht / Geräte\nHauptschalter",
    "ES": "Protección de sobrecarga\nIluminación / equipos\nInterruptor general",
    "PTBR": "Proteção de sobrecarga\nIluminação / equipamentos\nInterruptor geral",
    "PT": "Proteção de sobrecarga\nIluminação / equipamentos\nInterruptor principal",
    "RU": "Защита от перегрузки\nСвет / приборы\nОбщий выключатель",
    "CN": "过载保护\n照明 / 设备\n总开关",
    "JP": "過負荷保護\n照明 / 機器\n主回路スイッチ",
    "KO": "과부하 보호\n조명 / 장비\n메인 스위치",
    "TR": "Aşırı yük koruması\nAydınlatma / cihazlar\nAna şalter",
}


def diagram(lang):
    # Device names as the translated game shows them; powers and notes from the labels above.
    t = dict(L[lang])
    item, _, _ = names(lang)
    unit = "\u0412\u0442" if lang == "RU" else "W"
    t["solar"] = "%s \u00b7 100 %s" % (item("SolarPanel"), unit)
    t["wind"] = "%s \u00b7 400 %s" % (item("WindTurbine"), unit)
    t["water"] = "%s \u00b7 120 %s" % (item("WaterWheel"), unit)
    t["inverter"] = caps(item("Inverter"), lang)
    optional = t["bank"][t["bank"].rfind("("):] if "(" in t["bank"] else t["bank"][t["bank"].rfind("\uff08"):]
    t["bank"] = "%s %s" % (caps(item("PowerBank"), lang), optional)
    W, H = 1200, 430
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    fT = font(lang, 26, True)
    d.rounded_rectangle((10, 10, W - 10, H - 10), 14, fill=CARD, outline=LINE, width=2)
    # Sources
    d.rounded_rectangle((30, 50, 300, 325), 12, fill=CARD, outline=LINE, width=2)
    text(d, (50, 68), t["sources"], fT)
    src = "\n".join((t["solar"], t["wind"], t["water"]))
    text(d, (50, 112), src, fit(d, src, lang, 20, 230), spacing=10)
    text(d, (50, 210), t["src_note"], fit(d, t["src_note"], lang, 15, 230), MUTED)
    text(d, (50, 270), t["wire"], fit(d, t["wire"], lang, 15, 230), MUTED)
    text(d, (50, 294), t["wire_cost"], fit(d, t["wire_cost"], lang, 15, 230), MUTED)
    # Inverter
    d.rounded_rectangle((340, 80, 610, 260), 12, fill=ACCENT_BG, outline=ACCENT, width=3)
    text(d, (360, 96), t["inverter"], fit(d, t["inverter"], lang, 26, 230, True))
    text(d, (360, 140), t["inv_main"], fit(d, t["inv_main"], lang, 20, 230))
    text(d, (360, 186), t["inv_note"], fit(d, t["inv_note"], lang, 15, 230), MUTED)
    # Optional breaker, between the inverter and the household distribution.
    d.rounded_rectangle((650, 80, 870, 260), 12, fill=BG, outline=GREY, width=2)
    breaker = caps(item("Breaker"), lang)
    text(d, (670, 96), breaker, fit(d, breaker, lang, 24, 180, True))
    text(d, (670, 134), optional, fit(d, optional, lang, 16, 180), MUTED)
    note = BREAKER_NOTES[lang]
    text(d, (670, 173), note, fit(d, note, lang, 15, 180), spacing=6)
    # House
    d.rounded_rectangle((910, 50, 1170, 290), 12, fill=GREEN_BG, outline=GREEN, width=2)
    text(d, (932, 68), t["house"], fT)
    text(d, (932, 112), t["house_main"], fit(d, t["house_main"], lang, 20, 225), spacing=8)
    text(d, (932, 205), t["house_note"], fit(d, t["house_note"], lang, 15, 225), MUTED)
    # Arrows
    arrow(d, 305, 160, 335, 160, head=12)
    arrow(d, 615, 160, 645, 160, head=12)
    arrow(d, 875, 160, 905, 160, head=12)
    # Power bank
    d.line((475, 262, 475, 330), fill=ACCENT, width=5)
    d.polygon([(475, 262), (465, 278), (485, 278)], fill=ACCENT)
    d.polygon([(475, 330), (465, 314), (485, 314)], fill=ACCENT)
    text(d, (490, 286), t["store"], fit(d, t["store"], lang, 15, 190), MUTED)
    x0, x1 = 330, 640
    for x in range(x0, x1, 14):
        d.line((x, 332, min(x + 7, x1), 332), fill=GREY, width=2)
        d.line((x, 408, min(x + 7, x1), 408), fill=GREY, width=2)
    for y in range(332, 408, 14):
        d.line((x0, y, x0, min(y + 7, 408)), fill=GREY, width=2)
        d.line((x1, y, x1, min(y + 7, 408)), fill=GREY, width=2)
    text(d, (348, 342), t["bank"], fit(d, t["bank"], lang, 19, 274, True))
    text(d, (348, 376), t["bank_note"], fit(d, t["bank_note"], lang, 15, 274), MUTED)
    save(im, "diagram", lang)


# --- 1b. LiveWire Extended diagram (EN, FR: the languages of its documentation) -------------------

EXT = {
    "EN": {
        "title": "LIVEWIRE EXTENDED · HOW A BUILDING GETS POWER",
        "a": "WITHOUT A BOARD", "b": "WITH A BOARD (optional)", "c": "OUTDOORS",
        "inverter": "INVERTER", "house": "BUILDING", "board": "BREAKER BOARD", "terminal": "POWER TERMINAL",
        "zone": "ZONE", "points": "WIRED APPLIANCES", "wire": "electric wire",
        "a_link": "Connect the building",
        "a_house": "Every appliance has power,\nno wiring needed",
        "a_note": "An overload trips the whole network",
        "b_board": "8, 16 or 24 modules\nhung on an inside wall\nof the building",
        "b_breakers": "breakers\n15 / 20 / 30 A",
        "b_points": "Rooms (lights) and appliances,\neach wired to one breaker",
        "b_rules": "All power goes through the board:\n"
                   "· an appliance wired to no breaker has no power\n"
                   "· a board without breakers cuts the whole building\n"
                   "· an overloaded breaker trips alone, the rest stays on\n"
                   "· several boards in one building: each appliance on one of them",
        "c_zone": "drawn around the terminal,\nup to 16 x 16 tiles",
    },
    "FR": {
        "title": "LIVEWIRE EXTENDED · COMMENT UN BÂTIMENT REÇOIT LE COURANT",
        "a": "SANS TABLEAU", "b": "AVEC TABLEAU (facultatif)", "c": "DEHORS",
        "inverter": "ONDULEUR", "house": "BÂTIMENT", "board": "TABLEAU ÉLECTRIQUE", "terminal": "BORNE",
        "zone": "ZONE", "points": "APPAREILS RACCORDÉS", "wire": "fil électrique",
        "a_link": "Raccorder le bâtiment",
        "a_house": "Tous les appareils ont le courant,\naucun câblage",
        "a_note": "Une surcharge fait sauter tout le réseau",
        "b_board": "8, 16 ou 24 modules\naccroché à un mur intérieur\ndu bâtiment",
        "b_breakers": "disjoncteurs\n15 / 20 / 30 A",
        "b_points": "Pièces (lumières) et appareils,\nchacun raccordé à un disjoncteur",
        "b_rules": "Tout le courant passe par le tableau :\n"
                   "· un appareil raccordé à aucun disjoncteur n'a pas de courant\n"
                   "· un tableau sans disjoncteur coupe tout le bâtiment\n"
                   "· un disjoncteur en surcharge saute seul, le reste continue\n"
                   "· plusieurs tableaux dans un bâtiment : chaque appareil sur l'un d'eux",
        "c_zone": "tracée autour de la borne,\njusqu'à 16 x 16 cases",
    },
}


def box(d, xy, fill, outline, width=2):
    d.rounded_rectangle(xy, 12, fill=fill, outline=outline, width=width)


def labelled_arrow(d, x0, x1, y, label, lang):
    arrow(d, x0, y, x1, y, head=12)
    f = fit(d, label, lang, 14, x1 - x0 + 40)
    text(d, ((x0 + x1) // 2, y - 10), label, f, MUTED, anchor="md")


def extended_diagram(lang):
    t = EXT[lang]
    W, H = 1200, 760
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((10, 10, W - 10, H - 10), 14, fill=CARD, outline=LINE, width=2)
    text(d, (30, 28), t["title"], fit(d, t["title"], lang, 24, W - 60, True))
    fH = font(lang, 18, True)
    # Row A: inverter -> building, no board.
    text(d, (30, 78), t["a"], fH, ACCENT)
    box(d, (30, 108, 200, 198), ACCENT_BG, ACCENT, 3)
    text(d, (45, 138), t["inverter"], fit(d, t["inverter"], lang, 20, 145, True))
    labelled_arrow(d, 205, 455, 153, t["a_link"], lang)
    box(d, (460, 108, 880, 198), GREEN_BG, GREEN)
    text(d, (480, 120), t["house"], fit(d, t["house"], lang, 20, 380, True))
    text(d, (480, 150), t["a_house"], fit(d, t["a_house"], lang, 16, 380), spacing=4)
    text(d, (900, 140), t["a_note"], fit(d, t["a_note"], lang, 15, 270), MUTED)
    # Row B: inverter -> wire -> board -> breakers -> wired appliances, in the building.
    text(d, (30, 228), t["b"], fH, ACCENT)
    box(d, (270, 258, 1170, 600), GREEN_BG, GREEN)
    text(d, (290, 268), t["house"], fit(d, t["house"], lang, 18, 300, True), GREEN)
    box(d, (30, 320, 200, 410), ACCENT_BG, ACCENT, 3)
    text(d, (45, 350), t["inverter"], fit(d, t["inverter"], lang, 20, 145, True))
    labelled_arrow(d, 205, 335, 365, t["wire"], lang)
    box(d, (340, 300, 620, 440), BG, ACCENT, 2)
    text(d, (358, 312), t["board"], fit(d, t["board"], lang, 18, 250, True))
    text(d, (358, 344), t["b_board"], fit(d, t["b_board"], lang, 14, 250), MUTED, spacing=4)
    labelled_arrow(d, 625, 755, 365, t["b_breakers"].split("\n")[0], lang)
    text(d, (690, 385), t["b_breakers"].split("\n")[1], fit(d, "15 / 20 / 30 A", lang, 14, 120), MUTED, anchor="ma")
    box(d, (760, 300, 1150, 440), CARD, GREEN)
    text(d, (778, 312), t["points"], fit(d, t["points"], lang, 18, 360, True))
    text(d, (778, 344), t["b_points"], fit(d, t["b_points"], lang, 15, 360), spacing=4)
    rules = t["b_rules"]
    text(d, (290, 458), rules, fit(d, rules, lang, 16, 860), spacing=7)
    # Row C: terminal -> its outdoor zone.
    text(d, (30, 625), t["c"], fH, ACCENT)
    box(d, (30, 655, 200, 735), ACCENT_BG, ACCENT, 3)
    text(d, (45, 680), t["inverter"], fit(d, t["inverter"], lang, 20, 145, True))
    labelled_arrow(d, 205, 335, 695, t["wire"], lang)
    box(d, (340, 655, 620, 735), BG, ACCENT, 2)
    text(d, (358, 682), t["terminal"], fit(d, t["terminal"], lang, 18, 250, True))
    arrow(d, 625, 695, 755, 695, head=12)
    box(d, (760, 655, 1170, 735), GREEN_BG, GREEN)
    text(d, (778, 665), t["zone"], fit(d, t["zone"], lang, 18, 370, True))
    text(d, (778, 691), t["c_zone"], fit(d, t["c_zone"], lang, 14, 370), MUTED, spacing=3)
    save(im, "diagram_extended", lang)


# --- 2. Production charts -----------------------------------------------------------------------


def solar_w(h, length, factor=1.0):
    dawn = 13.0 - length / 2
    if h <= dawn or h >= dawn + length:
        return 0.0
    return 100.0 * math.sin(math.pi * (h - dawn) / length) * factor


def wind_w(v):
    if v < 10 or v > 85:
        return 0.0
    if v >= 30:
        return 400.0
    return 400.0 * (v / 30.0) ** 3


def plot(d, box, xs, series, xr, yr, xticks, yticks, lang, xlabel, ylabel):
    x0, y0, x1, y1 = box
    fS = font(lang, 14)

    def P(x, y):
        return (x0 + (x - xr[0]) / (xr[1] - xr[0]) * (x1 - x0), y1 - (y - yr[0]) / (yr[1] - yr[0]) * (y1 - y0))
    for yt in yticks:
        _, py = P(xr[0], yt)
        d.line((x0, py, x1, py), fill=(232, 228, 220), width=1)
        text(d, (x0 - 8, py), str(yt), fS, MUTED, anchor="rm")
    for xt in xticks:
        px, _ = P(xt, yr[0])
        text(d, (px, y1 + 8), str(xt), fS, MUTED, anchor="ma")
    d.line((x0, y1, x1, y1), fill=INK, width=2)
    d.line((x0, y0, x0, y1), fill=INK, width=2)
    text(d, ((x0 + x1) / 2, y1 + 30), xlabel, fS, MUTED, anchor="ma")
    text(d, (x0, y0 - 22), ylabel, fS, MUTED, anchor="lm")
    for col, ys, width, dashed in series:
        pts = [P(x, y) for x, y in zip(xs, ys)]
        if dashed:
            for i in range(0, len(pts) - 1, 2):
                d.line((pts[i], pts[i + 1]), fill=col, width=width)
        else:
            d.line(pts, fill=col, width=width, joint="curve")
    return P


def title(d, xy, s, lang, width):
    """Panel title, shrunk then wrapped on two lines when too wide."""
    for size in (19, 17, 15):
        f = font(lang, size, True)
        if tsize(d, s, f)[0] <= width:
            text(d, xy, s, f)
            return
    words = s.split(" ")
    if len(words) == 1:
        text(d, xy, s, f)
        return
    best = None
    for k in range(1, len(words)):
        a, b = " ".join(words[:k]), " ".join(words[k:])
        w = max(tsize(d, a, f)[0], tsize(d, b, f)[0])
        if best is None or w < best[0]:
            best = (w, a + "\n" + b)
    text(d, (xy[0], xy[1] - 8), best[1], f, spacing=2)


def production(lang):
    t = L[lang]
    W, H = 1200, 470
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    fS = font(lang, 14)
    panels = [(10, 380), (390, 770), (790, 1190)]
    for a, b in panels:
        d.rounded_rectangle((a, 10, b, H - 10), 12, fill=CARD, outline=LINE, width=2)
    # Solar day: day lengths giving 0.94 kWh (summer) and 0.60 kWh (winter) with a sine curve of 100 W.
    ls, lw = 0.94 * 1000 * math.pi / 200, 0.60 * 1000 * math.pi / 200
    xs = [i / 10 for i in range(0, 241)]
    title(d, (30, 28), t["c_solar"], lang, 340)
    plot(d, (70, 100, 360, 330), xs,
         [(ACCENT, [solar_w(x, ls) for x in xs], 4, False),
          (BLUE, [solar_w(x, lw) for x in xs], 4, False),
          (GREY, [solar_w(x, ls, 0.2) for x in xs], 3, True)],
         (0, 24), (0, 100), [0, 6, 12, 18, 24], [0, 25, 50, 75, 100], lang, t["hour"], "W")
    yy = 404
    for col, key, dashed in ((ACCENT, "summer", False), (BLUE, "winter", False), (GREY, "overcast", True)):
        if dashed:
            for x in range(30, 52, 8):
                d.line((x, yy, x + 4, yy), fill=col, width=4)
        else:
            d.line((30, yy, 52, yy), fill=col, width=4)
        text(d, (60, yy), t[key], fS, INK, anchor="lm")
        yy += 22
    # Wind curve
    xs = [i / 2 for i in range(0, 201)]
    title(d, (410, 28), t["c_wind"], lang, 345)
    P = plot(d, (450, 100, 750, 340), xs, [(ACCENT, [wind_w(x) for x in xs], 4, False)],
             (0, 100), (0, 400), [0, 10, 30, 85, 100], [0, 100, 200, 300, 400], lang, t["wind_axis"], "W")
    for v in (15, 25):
        px, py = P(v, wind_w(v))
        d.ellipse((px - 5, py - 5, px + 5, py + 5), fill=INK)
        text(d, (px + 8, py - 4), "%d W" % round(wind_w(v)), fS, INK, anchor="ld")
    text(d, (410, 412), t["brake"], fS, MUTED)
    # Daily energy
    title(d, (810, 28), t["c_daily"], lang, 370)
    data = [("g1", 3.8, 2.4), ("g2", 6.3, 4.3), ("g3", 4.8, 4.1)]
    bx0, by0, bx1, by1 = 850, 100, 1170, 340
    ymax = 7.0
    for yt in range(0, 8):
        py = by1 - yt / ymax * (by1 - by0)
        d.line((bx0, py, bx1, py), fill=(232, 228, 220), width=1)
        text(d, (bx0 - 8, py), str(yt), fS, MUTED, anchor="rm")
    d.line((bx0, by1, bx1, by1), fill=INK, width=2)
    d.line((bx0, by0, bx0, by1), fill=INK, width=2)
    text(d, (bx0, by0 - 22), "kWh", fS, MUTED, anchor="lm")
    gw = (bx1 - bx0) / 3
    for i, (g, s, w) in enumerate(data):
        gx = bx0 + i * gw + gw * 0.15
        bw = gw * 0.33
        for j, (val, col) in enumerate(((s, ACCENT), (w, BLUE))):
            x = gx + j * (bw + 4)
            d.rectangle((x, by1 - val / ymax * (by1 - by0), x + bw, by1), fill=col)
            # Value at the foot of the bar: the dashed need line (3.8) crosses the top of the 4.1 / 4.3 bars.
            text(d, (x + bw / 2, by1 - 6), ("%.1f" % val).replace(".", "," if lang in DECIMAL_COMMA else "."),
                 font(lang, 12, True), CARD, anchor="md")
        text(d, (bx0 + i * gw + gw / 2, by1 + 8), t[g], font(lang, 12), INK, anchor="ma")
    py = by1 - 3.8 / ymax * (by1 - by0)
    for x in range(bx0, bx1, 12):
        d.line((x, py, min(x + 6, bx1), py), fill=GREEN, width=3)
    text(d, (810, 400), t["need"], font(lang, 12), GREEN, anchor="lm")
    for k, (col, key) in enumerate(((ACCENT, "s_summer"), (BLUE, "s_winter"))):
        x = 810 + k * 160
        d.rectangle((x, 424, x + 16, 438), fill=col)
        text(d, (x + 24, 431), t[key], fS, INK, anchor="lm")
    save(im, "production", lang)


# --- 3. Recipes, read from the recipe scripts ---------------------------------------------------

# Tools are the tags of the scripts (tags[base:x] with mode:keep); their game item names.
TOOL_TAGS = {"screwdriver": "Screwdriver", "pliers": "Pliers", "sheetmetalsnips": "SheetMetalSnips",
             "hammer": "Hammer", "pipewrench": "PipeWrench"}
TOOL_FULL = {"Screwdriver": "Base.Screwdriver", "Pliers": "Base.Pliers", "SheetMetalSnips": "Base.SheetMetalSnips",
             "Hammer": "Base.Hammer", "PipeWrench": "Base.PipeWrench"}
ITEM_LINE = re.compile(r"^item (\d+) (?:tags\[base:(\w+)\]|\[([^\]]+)\])(.*)$")
OUTPUT_LINE = re.compile(r"^item (\d+) ([A-Za-z_][\w.]*)$")
# Full item type -> icon / table key: "Base.Mov_LiveWire_X" -> X, "LiveWire.Breaker15" -> Breaker15.
FULL_NAMES = dict((k, v) for k, v in TOOL_FULL.items())


def short(full):
    name = full.split(".", 1)[1]
    if name.startswith("Mov_LiveWire_"):
        return name[len("Mov_LiveWire_"):]
    return name


def strip_lua_comments(src):
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return re.sub(r"--[^\n]*", "", src)


def parse_recipes(path):
    """Every craftRecipe block of a recipe script: name, kind (craft / dismantle, by name: LWSoundproofKit dismantling
    uses timedAction = Making), level, inputs, tools, outputs."""
    with open(path, encoding="utf-8-sig") as f:
        src = strip_lua_comments(f.read())
    recipes = []
    for block in re.split(r"\bcraftRecipe\s+", src)[1:]:
        name = re.match(r"\w+", block).group(0)
        lvl = re.search(r"SkillRequired\s*=\s*Electricity:(\d+)", block)
        head, _, rest = block.partition("inputs")
        ins_src, _, outs_src = rest.partition("outputs")
        # Each section ends at its own closing brace: the scripts also declare `item` blocks between recipes.
        ins_src, outs_src = ins_src.split("}")[0], outs_src.split("}")[0]
        ins, tools, outs = [], [], []
        for line in ins_src.splitlines():
            line = line.strip().rstrip(",")
            if not line.startswith("item "):
                continue
            m = ITEM_LINE.match(line)
            if not m:
                raise ValueError("%s: unparsed input line %r" % (name, line))
            qty, tag, alts, flags = int(m.group(1)), m.group(2), m.group(3), m.group(4)
            if tag:
                key = TOOL_TAGS[tag]
                if "mode:keep" not in flags:
                    raise ValueError("%s: tag %s is consumed (no mode:keep)" % (name, tag))
                tools.append(key)
                continue
            if ";" in alts:
                # The only alternative list in the scripts: any of the three car batteries.
                if not all("CarBattery" in a for a in alts.split(";")):
                    raise ValueError("%s: unexpected alternatives %s" % (name, alts))
                key = "CarBattery1"
            else:
                key = short(alts)
                FULL_NAMES[key] = alts
            if "mode:keep" in flags:
                tools.append(key)
            else:
                ins.append((qty, key))
        for line in outs_src.splitlines():
            line = line.strip().rstrip(",")
            if not line.startswith("item "):
                continue
            m = OUTPUT_LINE.match(line)
            if not m:
                raise ValueError("%s: unparsed output line %r" % (name, line))
            key = short(m.group(2))
            FULL_NAMES[key] = m.group(2)
            outs.append((int(m.group(1)), key))
        if not ins or not outs:
            raise ValueError("%s: no inputs or outputs parsed" % name)
        recipes.append({"name": name, "kind": "dismantle" if name.startswith("LWDismantle") else "craft",
                        "level": int(lvl.group(1)) if lvl else None, "ins": ins, "tools": tools, "outs": outs})
    return recipes


BASE_RECIPE_LIST = parse_recipes(BASE_RECIPES)
EXT_RECIPE_LIST = parse_recipes(EXT_RECIPES)
RECIPE_SETS = {"base": BASE_RECIPE_LIST, "ext": EXT_RECIPE_LIST}
# Checks: the scripts hold 16 crafts and 15 dismantling recipes (base), 8 crafts (Extended); every dismantling
# recipe needs a screwdriver (the dismantling card states it).
if [r["kind"] for r in BASE_RECIPE_LIST].count("craft") != 16 or len(BASE_RECIPE_LIST) != 31:
    raise ValueError("LiveWire_recipes.txt: expected 16 crafts and 15 dismantling recipes")
if len(EXT_RECIPE_LIST) != 8 or any(r["kind"] != "craft" for r in EXT_RECIPE_LIST):
    raise ValueError("LiveWireExtended_recipes.txt: expected 8 crafts")
if not all("Screwdriver" in r["tools"] for r in BASE_RECIPE_LIST if r["kind"] == "dismantle"):
    raise ValueError("a dismantling recipe does not need a screwdriver")


def load_json(path):
    try:
        with open(path, encoding="utf-8-sig") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def names(lang):
    def tr(folders, name):
        out = {}
        for folder in folders:
            out.update(load_json(os.path.join(folder, "EN", name)))
            out.update(load_json(os.path.join(folder, lang, name)))
        return out
    game_items = tr([GAME_TR], "ItemName.json")
    game_ui = tr([GAME_TR], "IG_UI.json")
    mod_items = tr([MOD_TR, EXT_TR], "ItemName.json")
    recipes = tr([MOD_TR, EXT_TR], "Recipes.json")

    def item(key):
        if key == "CarBattery1":
            return L[lang]["any_car_battery"]
        full = FULL_NAMES[key]  # KeyError: an item the scripts do not know
        if full in mod_items:
            return mod_items[full]
        if full in game_items:
            return game_items[full]
        raise KeyError("no translation for %s (%s)" % (full, lang))
    return item, recipes, game_ui.get("IGUI_perks_Electricity", "Electrical")


def icon(key, size):
    im = Image.open(os.path.join(ICONS, key + ".png")).convert("RGBA")
    return im.resize((size, size), Image.NEAREST if im.width <= 32 else Image.LANCZOS)


def dismantle_rows(lang, item):
    """Dismantling card rows: the screwdriver for all, then each extra tool with the devices it serves."""
    dis = [r for r in BASE_RECIPE_LIST if r["kind"] == "dismantle"]
    extra = {}
    for r in dis:
        for tool in r["tools"]:
            if tool != "Screwdriver":
                extra.setdefault(tool, []).append(r["ins"][0][1])
    sep = "、" if lang in ("CN", "JP") else ", "
    rows = [("Screwdriver", L[lang]["dis_all"] % len(dis))]
    for tool, keys in extra.items():
        rows.append((tool, L[lang]["dis_extra"] % (item(tool), sep.join(item(k) for k in keys))))
    return rows


def recipe_book(lang, which):
    """Recipe book, 640 px wide: Steam shows description images in a column of about 640 px, so a wider
    board would be scaled down and become unreadable. Crafts as cards; dismantling as one compact card."""
    t = L[lang]
    item, rnames, skill = names(lang)
    W, PAD = 640, 12
    fT, fS = font(lang, 30, True), font(lang, 15)
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    recs = [r for r in RECIPE_SETS[which] if r["kind"] == "craft"]
    dis_rows = dismantle_rows(lang, item) if which == "base" else []
    cards = [(r, 84 + ((len(r["ins"]) + 1) // 2) * 40 + 8) for r in recs]
    dis_h = 44 + 26 * len(dis_rows) + 14 if dis_rows else 0
    H = 70 + sum(ch + 10 for _, ch in cards) + (dis_h + 10 if dis_rows else 0) + 6
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    text(d, (PAD + 4, 18), t["recipes"] if which == "base" else "LIVEWIRE EXTENDED · " + t["recipes"], fT)
    text(d, (W - PAD - 4, 32), t["tools"], fS, MUTED, anchor="ra")
    y = 66
    for r, ch in cards:
        rk, lvl, ins, tools, outs = r["name"], r["level"], r["ins"], r["tools"], r["outs"]
        if rk not in rnames:
            raise KeyError("no translation for recipe %s (%s)" % (rk, lang))
        d.rounded_rectangle((PAD, y, W - PAD, y + ch), 12, fill=CARD, outline=LINE, width=2)
        # Header: result icon(s), recipe name, skill badge; tools on the right.
        ox = PAD + 12
        for q, o in outs:
            ic = icon(o, 52)
            im.paste(ic, (ox, y + 12), ic)
            ox += 56
        tools_w = 40 * len(tools)
        rn = rnames[rk]
        text(d, (ox + 8, y + 12), rn, fit(d, rn, lang, 20, W - PAD - 16 - tools_w - (ox + 8), True))
        lv = t["no_level"] if lvl is None else t["level"] % (skill, lvl)
        bw = tsize(probe, lv, fS)[0]
        d.rounded_rectangle((ox + 8, y + 44, ox + 8 + bw + 18, y + 68), 9,
                            fill=ACCENT_BG if lvl else (235, 235, 235))
        text(d, (ox + 17, y + 56), lv, fS, ACCENT if lvl else MUTED, anchor="lm")
        x = W - PAD - 12
        for tl in reversed(tools):
            ic = icon(tl, 32)
            im.paste(ic, (x - 32, y + 16), ic)
            x -= 40
        # Ingredients on two columns.
        d.line((PAD + 12, y + 78, W - PAD - 12, y + 78), fill=LINE, width=1)
        colw = (W - 2 * PAD - 24) / 2
        for k, (q, it) in enumerate(ins):
            cx = PAD + 12 + (k % 2) * colw
            cy = y + 86 + (k // 2) * 40
            ic = icon(it, 32)
            im.paste(ic, (int(cx), cy), ic)
            label = "%d× %s" % (q, item(it))
            text(d, (cx + 40, cy + 16), label, fit(d, label, lang, 16, colw - 48), INK, anchor="lm")
        y += ch + 10
    if dis_rows:
        d.rounded_rectangle((PAD, y, W - PAD, y + dis_h), 12, fill=CARD, outline=LINE, width=2)
        text(d, (PAD + 12, y + 12), t["dis_title"], font(lang, 20, True), ACCENT)
        text(d, (W - PAD - 12, y + 16), t["no_level"], fS, MUTED, anchor="ra")
        for k, (tool, label) in enumerate(dis_rows):
            yy = y + 44 + 26 * k
            ic = icon(tool, 24)
            im.paste(ic, (PAD + 12, yy), ic)
            text(d, (PAD + 44, yy + 12), label, fit(d, label, lang, 16, W - 2 * PAD - 56), INK, anchor="lm")
    save(im, "recipe_book" if which == "base" else "recipe_book_extended", lang)


# --- 4. Equipment boards ------------------------------------------------------------------------

# (icon key, figures shown under the name; language-neutral)
EQUIP = [("SolarPanel", "100 W"), ("WindTurbine", "400 W · 10-85 km/h"), ("WaterWheel", "120 W"),
         ("Inverter", "1500 W max"), ("InverterCabinet", "4500 W max"), ("PowerBank", "4 × "), ("Breaker", None),
         ("BatteryAlarm", "< 20 %"), ("WaterPump", "250 W · 5 L/min")]


def sprite(key):
    """Tile sprite from the mod's pack, extracted once into docs/images/icons/tiles (see collect step)."""
    p = os.path.join(ICONS, "tiles", key + ".png")
    if not os.path.exists(p):
        p = os.path.join(ICONS, key + ".png")
    im = Image.open(p).convert("RGBA")
    return im.crop(im.getbbox())


def wrap2(d, s, lang, size, width):
    """Name on one line, or on two lines at the most balanced space when one line is too wide."""
    f = font(lang, size, True)
    if tsize(d, s, f)[0] <= width:
        return s, f
    words = s.split(" ")
    best = None
    for k in range(1, len(words)):
        a, b = " ".join(words[:k]), " ".join(words[k:])
        w = max(tsize(d, a, f)[0], tsize(d, b, f)[0])
        if best is None or w < best[0]:
            best = (w, a + "\n" + b)
    if best is None:
        return s, fit(d, s, lang, size, width, True)
    return best[1], fit(d, best[1], lang, size, width, True)


def board(lang, entries, name):
    """Row of devices: picture, name, figures. entries = [(icon key, figure text)]."""
    item, _, _ = names(lang)
    W, H = 1200, 330
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((10, 10, W - 10, H - 10), 14, fill=CARD, outline=LINE, width=2)
    cw = (W - 40) / len(entries)
    # Common scale, enlarged up to 2x for the small wall devices so they stay readable.
    base = min(min(150 / sprite(key).width, 190 / sprite(key).height) for key, _ in entries)
    for i, (key, fig) in enumerate(entries):
        cx = 20 + cw * i + cw / 2
        sp = sprite(key)
        k = min(2 * base, 150 / sp.width, 190 / sp.height)
        sp = sp.resize((max(1, int(sp.width * k)), max(1, int(sp.height * k))), Image.LANCZOS)
        im.paste(sp, (int(cx - sp.width / 2), 210 - sp.height), sp)
        nm, f = wrap2(d, item(key), lang, 17, cw - 12)
        text(d, (cx, 228), nm, f, INK, anchor="ma", align="center")
        f = font(lang, 15)
        if key == "PowerBank":
            w = tsize(d, fig, f)[0] + 26
            text(d, (cx - w / 2, 292), fig, f, ACCENT, anchor="lm")
            ic = icon("CarBattery1", 24)
            im.paste(ic, (int(cx - w / 2 + w - 24), 280), ic)
        else:
            text(d, (cx, 292), fig, fit(d, fig, lang, 15, cw - 10), ACCENT, anchor="mm")
    save(im, name, lang)


def equipment(lang):
    board(lang, [(key, BREAKER_FIG[lang] if key == "Breaker" else fig) for key, fig in EQUIP], "equipment")


def equipment_extended(lang):
    """Extended devices: terminal, breaker boards, breakers (rating = A x 120 V, as the code computes it), twilight switch."""
    t = L[lang]
    entries = [("Terminal", t["fig_zone"]), ("Panel8", t["fig_modules"] % 8),
               ("Panel16", t["fig_modules"] % 16), ("Panel24", t["fig_modules"] % 24)]
    for amps in (15, 20, 30):
        entries.append(("Breaker%d" % amps, t["fig_amp"] % (amps, amps * 120, t["w_unit"])))
    entries.append(("TwilightSwitch", t["fig_night"]))
    board(lang, entries, "equipment_extended")


# --- 5. Icons ----------------------------------------------------------------------------------

ITEM_ICON = re.compile(r"\bitem\s+(\w+)\s*\{[^}]*?\bIcon\s*=\s*(\w+)", re.S)
# Game packs that hold the inventory icons (the tile packs are large and hold none).
ICON_PACKS = ("UI.pack", "UI2.pack")


def pack_icons(wanted):
    """Inventory icons (Item_<name>) read from the game's texture packs, as the game shows them: the packed
    sub-image placed at its offset in its full frame. Pack format of TexturePackPage.loadFromPackFile, version 1
    ("PZPK", version, page count; per page: name, entries, mask, entries x (name, x, y, w, h, ox, oy, full w,
    full h), PNG length, PNG); integers little-endian, strings prefixed by their length."""
    import io
    import struct
    found = {}
    for pack in ICON_PACKS:
        with open(os.path.join(GAME_MEDIA, "texturepacks", pack), "rb") as f:
            b = f.read()
        if b[:4] != b"PZPK" or struct.unpack_from("<i", b, 4)[0] != 1:
            raise ValueError("%s: unsupported pack format" % pack)
        pages, o = struct.unpack_from("<i", b, 8)[0], 12
        for _ in range(pages):
            n = struct.unpack_from("<i", b, o)[0]
            o += 4 + n
            count = struct.unpack_from("<i", b, o)[0]
            o += 8
            entries = []
            for _ in range(count):
                n = struct.unpack_from("<i", b, o)[0]
                name = b[o + 4:o + 4 + n].decode("latin-1")
                o += 4 + n
                entries.append((name, struct.unpack_from("<8i", b, o)))
                o += 32
            size = struct.unpack_from("<i", b, o)[0]
            png = b[o + 4:o + 4 + size]
            o += 4 + size
            page = None
            for name, (x, y, w, h, ox, oy, fw, fh) in entries:
                if name.startswith("Item_") and name[5:] in wanted and name[5:] not in found:
                    page = page or Image.open(io.BytesIO(png)).convert("RGBA")
                    im = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
                    im.paste(page.crop((x, y, x + w, y + h)), (ox, oy))
                    found[name[5:]] = im
    missing = set(wanted) - set(found)
    if missing:
        raise KeyError("icons not found in the game packs: %s" % ", ".join(sorted(missing)))
    return found


def collect_icons():
    """Copy the inventory textures of both mods into docs/images/icons; mod items that use a vanilla icon
    (Icon = Remote...) get that icon from the game packs, as in game. Other vanilla icons are kept as they are."""
    base_tex = os.path.join(BASE_MOD, "textures")
    ext_tex = os.path.join(EXT_MOD, "textures")
    copies = {}
    vanilla = {}
    for script in (os.path.join(BASE_MOD, "scripts", "LiveWire_items.txt"),
                   os.path.join(EXT_MOD, "scripts", "LiveWireExtended_items.txt")):
        with open(script, encoding="utf-8-sig") as f:
            for key, ic in ITEM_ICON.findall(strip_lua_comments(f.read())):
                if not any(os.path.exists(os.path.join(t, "Item_%s.png" % ic)) for t in (base_tex, ext_tex)):
                    vanilla[key] = ic
    for key, im in pack_icons(set(vanilla.values())).items():
        for item_key, ic in vanilla.items():
            if ic == key:
                im.save(os.path.join(ICONS, item_key + ".png"), optimize=True)
    for f in os.listdir(base_tex):
        m = re.fullmatch(r"Item_LiveWire(\w+)\.png", f)
        if m:
            copies[m.group(1)] = os.path.join(base_tex, f)
    for f in os.listdir(ext_tex):
        m = re.fullmatch(r"Item_LWX(\w+)\.png", f)
        if not m:
            continue
        if m.group(1) == "Panel":  # one texture for the 8, 16 and 24 module boards
            for n in (8, 16, 24):
                copies["Panel%d" % n] = os.path.join(ext_tex, f)
        else:
            copies[m.group(1)] = os.path.join(ext_tex, f)
    for key, src in sorted(copies.items()):
        dst = os.path.join(ICONS, key + ".png")
        with open(src, "rb") as fi, open(dst, "wb") as fo:
            fo.write(fi.read())


def main():
    langs = [a.upper() for a in sys.argv[1:]] or LANGS
    collect_icons()
    for lang in langs:
        diagram(lang)
        if lang in EXT:
            extended_diagram(lang)
        production(lang)
        recipe_book(lang, "base")
        recipe_book(lang, "ext")
        equipment(lang)
        equipment_extended(lang)


if __name__ == "__main__":
    main()
