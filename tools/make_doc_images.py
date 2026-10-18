"""Documentation images for the README, the wiki and the Steam Workshop page.

    python tools/make_doc_images.py [LANG ...]      (default: all languages)

Writes docs/img/<name>_<lang>.png: diagram (how it works), production (charts), recipe_book (recipes,
640 px wide for the Steam page), equipment (device board).
Only Pillow is needed. Figures come from the mod's model (docs/wiki/_facts.md); the solar day is the
sine curve of LW_Physics.solarCurve with the day lengths that give the documented 0.94 / 0.60 kWh.
Item names come from the game's translations (vanilla items) and the mod's translations (mod items).
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "img")
ICONS = os.path.join(ROOT, "docs", "icons")
MOD_TR = os.path.join(ROOT, "Contents", "mods", "batman_LiveWire", "42.21", "media", "lua", "shared", "Translate")
GAME_TR = os.environ.get("PZ_TRANSLATE", r"D:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua\shared\Translate")
FONTS = os.environ.get("FONTS_DIR", r"C:\Windows\Fonts")
LANGS = ["EN", "FR", "DE", "ES", "PTBR", "PT", "RU", "CN", "JP", "KO"]

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
        "need": "need 4.1 kWh/day (fridge-freezer + 10 lights)", "s_summer": "Summer", "s_winter": "Winter",
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
        "need": "besoin 4,1 kWh/jour (réfrigérateur-congélateur + 10 lampes)", "s_summer": "Été", "s_winter": "Hiver",
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
        "need": "Bedarf 4,1 kWh/Tag (Kühl-Gefrierschrank + 10 Lampen)", "s_summer": "Sommer", "s_winter": "Winter",
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
        "need": "necesidad 4,1 kWh/día (nevera-congelador + 10 luces)", "s_summer": "Verano", "s_winter": "Invierno",
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
        "need": "consumo 4,1 kWh/dia (geladeira-freezer + 10 luzes)", "s_summer": "Verão", "s_winter": "Inverno",
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
        "need": "consumo 4,1 kWh/dia (frigorífico-congelador + 10 luzes)", "s_summer": "Verão", "s_winter": "Inverno",
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
        "need": "нужно 4,1 кВт·ч/сутки (холодильник с морозилкой + 10 ламп)", "s_summer": "Лето", "s_winter": "Зима",
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
        "need": "需求 4.1 kWh/天（冷藏冷冻冰箱 + 10 盏灯）", "s_summer": "夏季", "s_winter": "冬季",
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
        "need": "必要量 4.1 kWh/日（冷凍冷蔵庫 + 照明10個）", "s_summer": "夏", "s_winter": "冬",
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
        "need": "필요량 4.1 kWh/일 (냉장냉동고 + 조명 10개)", "s_summer": "여름", "s_winter": "겨울",
        "g1": "태양광 패널 4개", "g2": "패널 6개\n+ 풍력 터빈 1대", "g3": "물레방아 1개\n+ 패널 2개",
        "recipes": "레시피", "no_level": "레벨 없음", "tools": "도구 (유지)", "level": "%s %d",
        "any_car_battery": "자동차 배터리 (아무거나)",
    },
}

# --- Drawing helpers ----------------------------------------------------------------------------


def text(d, xy, s, f, fill=INK, anchor="la", spacing=4):
    d.multiline_text(xy, s, font=f, fill=fill, anchor=anchor, spacing=spacing)


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


def save(im, name, lang):
    os.makedirs(OUT, exist_ok=True)
    p = os.path.join(OUT, "%s_%s.png" % (name, lang.lower()))
    im.save(p, optimize=True)
    print("wrote", os.path.relpath(p, ROOT), im.size)


# --- 1. Diagram ---------------------------------------------------------------------------------


def diagram(lang):
    # Device names as the translated game shows them; powers and notes from the labels above.
    t = dict(L[lang])
    item, _, _ = names(lang)
    unit = "\u0412\u0442" if lang == "RU" else "W"
    t["solar"] = "%s \u00b7 100 %s" % (item("SolarPanel"), unit)
    t["wind"] = "%s \u00b7 400 %s" % (item("WindTurbine"), unit)
    t["water"] = "%s \u00b7 120 %s" % (item("WaterWheel"), unit)
    t["inverter"] = item("Inverter").upper()
    t["bank"] = "%s %s" % (item("PowerBank").upper(), t["bank"][t["bank"].rfind("("):] if "(" in t["bank"]
                           else t["bank"][t["bank"].rfind("\uff08"):])
    W, H = 1200, 400
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    fT, fS = font(lang, 26, True), font(lang, 15)
    d.rounded_rectangle((10, 10, W - 10, H - 10), 14, fill=CARD, outline=LINE, width=2)
    # Sources
    d.rounded_rectangle((40, 50, 330, 290), 12, fill=CARD, outline=LINE, width=2)
    text(d, (62, 68), t["sources"], fT)
    src = "\n".join((t["solar"], t["wind"], t["water"]))
    text(d, (62, 112), src, fit(d, src, lang, 20, 255), spacing=10)
    text(d, (62, 228), t["src_note"], fit(d, t["src_note"], lang, 15, 255), MUTED)
    # Inverter
    d.rounded_rectangle((470, 80, 760, 240), 12, fill=ACCENT_BG, outline=ACCENT, width=3)
    text(d, (492, 96), t["inverter"], fit(d, t["inverter"], lang, 26, 250, True))
    text(d, (492, 140), t["inv_main"], fit(d, t["inv_main"], lang, 20, 250))
    text(d, (492, 186), t["inv_note"], fit(d, t["inv_note"], lang, 15, 250), MUTED)
    # House
    d.rounded_rectangle((900, 50, 1160, 290), 12, fill=GREEN_BG, outline=GREEN, width=2)
    text(d, (922, 68), t["house"], fT)
    text(d, (922, 112), t["house_main"], fit(d, t["house_main"], lang, 20, 225), spacing=8)
    text(d, (922, 205), t["house_note"], fit(d, t["house_note"], lang, 15, 225), MUTED)
    # Arrows
    arrow(d, 335, 160, 465, 160)
    text(d, (400, 150), t["wire"], fit(d, t["wire"], lang, 15, 125), MUTED, anchor="md")
    text(d, (400, 172), t["wire_cost"], fit(d, t["wire_cost"], lang, 15, 125), MUTED, anchor="ma")
    arrow(d, 765, 160, 895, 160)
    text(d, (830, 150), t["house_power"], fit(d, t["house_power"], lang, 15, 125), MUTED, anchor="md")
    # Power bank
    d.line((615, 242, 615, 300), fill=ACCENT, width=5)
    d.polygon([(615, 242), (605, 258), (625, 258)], fill=ACCENT)
    d.polygon([(615, 300), (605, 284), (625, 284)], fill=ACCENT)
    text(d, (630, 262), t["store"], fS, MUTED)
    x0, x1 = 470, 760
    for x in range(x0, x1, 14):
        d.line((x, 302, min(x + 7, x1), 302), fill=GREY, width=2)
        d.line((x, 378, min(x + 7, x1), 378), fill=GREY, width=2)
    for y in range(302, 378, 14):
        d.line((x0, y, x0, min(y + 7, 378)), fill=GREY, width=2)
        d.line((x1, y, x1, min(y + 7, 378)), fill=GREY, width=2)
    text(d, (488, 312), t["bank"], fit(d, t["bank"], lang, 19, 255, True))
    text(d, (488, 346), t["bank_note"], fS, MUTED)
    save(im, "diagram", lang)


# --- 2. Production charts -----------------------------------------------------------------------


def solar_w(h, length, factor=1.0):
    dawn = 13.0 - length / 2
    if h <= dawn or h >= dawn + length:
        return 0.0
    return 100.0 * math.sin(math.pi * (h - dawn) / length) * factor


def wind_w(v):
    if v < 10 or v > 85:
        return 0.0
    if v >= 45:
        return 400.0
    return 400.0 * ((v - 10) / 35.0) ** 3


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
             (0, 100), (0, 400), [0, 10, 25, 45, 85, 100], [0, 100, 200, 300, 400], lang, t["wind_axis"], "W")
    for v in (25, 40):
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
            text(d, (x + bw / 2, by1 - val / ymax * (by1 - by0) + 4), ("%.1f" % val).replace(
                ".", "," if lang in ("FR", "DE", "ES", "PTBR", "PT", "RU") else "."), font(lang, 12, True), CARD, anchor="ma")
        text(d, (bx0 + i * gw + gw / 2, by1 + 8), t[g], font(lang, 12), INK, anchor="ma")
    py = by1 - 4.1 / ymax * (by1 - by0)
    for x in range(bx0, bx1, 12):
        d.line((x, py, min(x + 6, bx1), py), fill=GREEN, width=3)
    text(d, (810, 400), t["need"], font(lang, 12), GREEN, anchor="lm")
    for k, (col, key) in enumerate(((ACCENT, "s_summer"), (BLUE, "s_winter"))):
        x = 810 + k * 160
        d.rectangle((x, 424, x + 16, 438), fill=col)
        text(d, (x + 24, 431), t[key], fS, INK, anchor="lm")
    save(im, "production", lang)


# --- 3. Recipe board ----------------------------------------------------------------------------

# (recipe key, level or None, [(qty, item)], [tools], [(qty, output)])
RECIPES = [
    ("LWMakeVoltageTester", 1, [(1, "ElectronicsScrap"), (1, "ElectricWire"), (1, "LightBulb"), (1, "Battery")],
     ["Screwdriver"], [(1, "VoltageTester")]),
    ("LWSalvageSolarCell", None, [(1, "Calculator")], ["Screwdriver"], [(1, "ElectronicsScrap"), (1, "SolarCell")]),
    ("LWMakePowerBankKit", 2, [(2, "ElectronicsScrap"), (3, "ElectricWire"), (1, "SheetMetal"), (4, "Screws")],
     ["Screwdriver", "Pliers"], [(1, "PowerBank")]),
    ("LWMakeBatteryAlarmKit", 2, [(1, "ElectronicsScrap"), (1, "ElectricWire"), (1, "Amplifier")],
     ["Screwdriver"], [(1, "BatteryAlarm")]),
    ("LWMakeSoundproofKit", 2, [(4, "Plank"), (10, "Nails"), (4, "RippedSheets")], ["Hammer"],
     [(1, "SoundproofKit")]),
    ("LWMakeSolarPanelKit", 3, [(10, "SolarCell"), (1, "SheetMetal"), (2, "ElectricWire"), (4, "Screws"),
                                (1, "Glue")], ["Screwdriver", "Pliers"], [(1, "SolarPanel")]),
    ("LWMakeBreakerKit", 3, [(2, "ElectronicsScrap"), (1, "ElectricWire"), (1, "SmallSheetMetal"), (2, "Screws")],
     ["Screwdriver"], [(1, "Breaker")]),
    ("LWMakeInverterKit", 5, [(4, "ElectronicsScrap"), (2, "Amplifier"), (3, "ElectricWire"),
                              (1, "SmallSheetMetal"), (4, "Screws")], ["Screwdriver", "Pliers"], [(1, "Inverter")]),
    ("LWMakeWindTurbineKit", 6, [(2, "Speaker"), (3, "ElectricWire"), (4, "ElectronicsScrap"), (2, "SheetMetal"),
                                 (2, "MetalBar"), (1, "Pipe"), (6, "Screws")], ["Screwdriver", "Pliers", "Hammer"],
     [(1, "WindTurbine")]),
    ("LWMakeDeepCycleBattery", 6, [(2, "CarBattery1"), (2, "ElectricWire"), (1, "ScrapMetal")], ["Pliers"],
     [(1, "DeepCycleBattery")]),
    ("LWMakeWaterWheel", 7, [(8, "Plank"), (20, "Nails"), (2, "Speaker"), (3, "ElectricWire"),
                             (4, "ElectronicsScrap"), (1, "MetalBar")], ["Hammer", "Screwdriver"],
     [(1, "WaterWheel")]),
    ("LWMakeWaterPump", 6, [(3, "ElectronicsScrap"), (2, "ElectricWire"), (2, "MetalPipe"), (1, "SmallSheetMetal"),
                            (4, "Screws")], ["Screwdriver", "PipeWrench"], [(1, "WaterPump")]),
    ("LWMakeSolarCellFromScrap", 8, [(5, "ElectronicsScrap"), (1, "Aluminum")], ["Pliers"], [(1, "SolarCell")]),
]

MOD_ITEMS = {"VoltageTester": "LiveWire.VoltageTester", "SolarCell": "LiveWire.SolarCell",
             "DeepCycleBattery": "LiveWire.DeepCycleBattery", "SoundproofKit": "LiveWire.SoundproofKit",
             "SolarPanel": "Base.Mov_LiveWire_SolarPanel", "WindTurbine": "Base.Mov_LiveWire_WindTurbine",
             "WaterWheel": "Base.Mov_LiveWire_WaterWheel", "Inverter": "Base.Mov_LiveWire_Inverter",
             "PowerBank": "Base.Mov_LiveWire_PowerBank", "Breaker": "Base.Mov_LiveWire_Breaker",
             "BatteryAlarm": "Base.Mov_LiveWire_BatteryAlarm", "WaterPump": "Base.Mov_LiveWire_WaterPump"}


def load_json(path):
    try:
        with open(path, encoding="utf-8-sig") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def names(lang):
    def tr(folder, name):
        base = load_json(os.path.join(folder, "EN", name))
        base.update(load_json(os.path.join(folder, lang, name)))
        return base
    game_items = tr(GAME_TR, "ItemName.json")
    game_ui = tr(GAME_TR, "IG_UI.json")
    mod_items = tr(MOD_TR, "ItemName.json")
    recipes = tr(MOD_TR, "Recipes.json")

    def item(key):
        if key == "CarBattery1":
            return L[lang]["any_car_battery"]
        if key in MOD_ITEMS:
            return mod_items.get(MOD_ITEMS[key], key)
        return game_items.get("Base." + key, key)
    return item, recipes, game_ui.get("IGUI_perks_Electricity", "Electrical")


def icon(key, size):
    im = Image.open(os.path.join(ICONS, key + ".png")).convert("RGBA")
    return im.resize((size, size), Image.NEAREST if im.width <= 32 else Image.LANCZOS)


def recipes(lang):
    """Recipe book, 640 px wide: Steam shows description images in a column of about
    640 px, so a wider board would be scaled down and become unreadable."""
    t = L[lang]
    item, rnames, skill = names(lang)
    W, PAD = 640, 12
    fT, fR, fS, fI = font(lang, 30, True), font(lang, 20, True), font(lang, 15), font(lang, 16)
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    cards = []
    for rk, lvl, ins, tools, outs in RECIPES:
        rows = (len(ins) + 1) // 2
        cards.append((rk, lvl, ins, tools, outs, 84 + rows * 40 + 8))
    H = 70 + sum(c[-1] + 10 for c in cards) + 6
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    text(d, (PAD + 4, 18), t["recipes"], fT)
    text(d, (W - PAD - 4, 32), t["tools"], fS, MUTED, anchor="ra")
    y = 66
    for rk, lvl, ins, tools, outs, ch in cards:
        d.rounded_rectangle((PAD, y, W - PAD, y + ch), 12, fill=CARD, outline=LINE, width=2)
        # Header: result icon(s), recipe name, skill badge; tools on the right.
        ox = PAD + 12
        for q, o in outs:
            ic = icon(o, 52)
            im.paste(ic, (ox, y + 12), ic)
            ox += 56
        tools_w = 40 * len(tools)
        rn = rnames.get(rk, rk)
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
    save(im, "recipe_book", lang)


# --- 4. Equipment board ------------------------------------------------------------------------

# (icon key, figures shown under the name; language-neutral)
EQUIP = [("SolarPanel", "100 W"), ("WindTurbine", "400 W \u00b7 10-85 km/h"), ("WaterWheel", "120 W"),
         ("Inverter", "1500 W max"), ("PowerBank", "4 \u00d7 "), ("Breaker", "> 1500 W"),
         ("BatteryAlarm", "< 20 %"), ("WaterPump", "250 W · 5 L/min")]


def sprite(key):
    """Tile sprite from the mod's pack, extracted once into docs/icons/tiles (see collect step)."""
    p = os.path.join(ICONS, "tiles", key + ".png")
    if not os.path.exists(p):
        p = os.path.join(ICONS, key + ".png")
    im = Image.open(p).convert("RGBA")
    return im.crop(im.getbbox())


def equipment(lang):
    item, _, _ = names(lang)
    W, H = 1200, 330
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((10, 10, W - 10, H - 10), 14, fill=CARD, outline=LINE, width=2)
    cw = (W - 40) / len(EQUIP)
    # Common scale, enlarged up to 2x for the small wall devices so they stay readable.
    base = min(min(150 / sprite(key).width, 190 / sprite(key).height) for key, _ in EQUIP)
    for i, (key, fig) in enumerate(EQUIP):
        cx = 20 + cw * i + cw / 2
        sp = sprite(key)
        k = min(2 * base, 150 / sp.width, 190 / sp.height)
        sp = sp.resize((max(1, int(sp.width * k)), max(1, int(sp.height * k))), Image.LANCZOS)
        im.paste(sp, (int(cx - sp.width / 2), 220 - sp.height), sp)
        name = item(key)
        text(d, (cx, 236), name, fit(d, name, lang, 17, cw - 12, True), INK, anchor="ma")
        f = font(lang, 15)
        if key == "PowerBank":
            w = tsize(d, fig, f)[0] + 26
            text(d, (cx - w / 2, 274), fig, f, ACCENT, anchor="lm")
            ic = icon("CarBattery1", 24)
            im.paste(ic, (int(cx - w / 2 + w - 24), 262), ic)
        else:
            text(d, (cx, 274), fig, f, ACCENT, anchor="mm")
    save(im, "equipment", lang)


def main():
    langs = [a.upper() for a in sys.argv[1:]] or LANGS
    for lang in langs:
        diagram(lang)
        production(lang)
        recipes(lang)
        equipment(lang)


if __name__ == "__main__":
    main()
