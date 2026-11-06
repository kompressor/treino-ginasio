import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Mostrador "Jorge Verde" - Forerunner 965 (454x454 AMOLED)
// Hora em gradiente, data em PT, bateria, recuperacao e distancia do dia.
class JorgeFaceView extends WatchUi.WatchFace {

    // Cores
    const ACCENT   = 0x2EE86A;
    const WHITE    = 0xFFFFFF;
    const SOFT     = 0xC8C8C8;
    const GREY     = 0x8A8A8A;
    const TICK_OFF = 0x262626;
    const TICK_5   = 0x4A4A4A;
    const RED      = 0xFF4D4D;
    const ORANGE   = 0xFFA000;

    // Metricas das fontes (ascendente = distancia do topo a linha de base)
    const ASC_BIG  = 150;
    const CAP_BIG  = 164;
    const DIG_H    = 166;
    const BASE_Y   = 0.67;  // linha de base da hora (fraccao da altura)  // altura dos bitmaps dos digitos (linha de base em baixo)
    const ASC_UNIT = 26;
    const ASC_DATE = 52;
    const CAP_DATE = 36;

    var DIAS  = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"];

    var MESES = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"];

    var _sleep = false;
    var _w = 454;
    var _h = 454;
    var _cx = 227;
    var _cy = 227;

    var fBig;
    var fUnit;
    var fDate;
    var icDistance;
    var icRecovery;
    var icBatteryTop;

    // Digitos em gradiente (bitmaps) - so os 4 em uso ficam em memoria
    var H_IDS = [Rez.Drawables.H0, Rez.Drawables.H1, Rez.Drawables.H2, Rez.Drawables.H3, Rez.Drawables.H4,
                 Rez.Drawables.H5, Rez.Drawables.H6, Rez.Drawables.H7, Rez.Drawables.H8, Rez.Drawables.H9];
    var M_IDS = [Rez.Drawables.M0, Rez.Drawables.M1, Rez.Drawables.M2, Rez.Drawables.M3, Rez.Drawables.M4,
                 Rez.Drawables.M5, Rez.Drawables.M6, Rez.Drawables.M7, Rez.Drawables.M8, Rez.Drawables.M9];
    var _digKey = [-1, -1, -1, -1];
    var _digBmp = [null, null, null, null];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _cx = _w / 2;
        _cy = _h / 2;
        fBig  = WatchUi.loadResource(Rez.Fonts.Big);
        fUnit = WatchUi.loadResource(Rez.Fonts.Unit);
        fDate = WatchUi.loadResource(Rez.Fonts.Date);
        icDistance = WatchUi.loadResource(Rez.Drawables.IcDistance);
        icRecovery = WatchUi.loadResource(Rez.Drawables.IcRecovery);
        icBatteryTop = WatchUi.loadResource(Rez.Drawables.IcBatteryTop);
    }

    function onEnterSleep() {
        _sleep = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() {
        _sleep = false;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        var clock = System.getClockTime();
        var ds = System.getDeviceSettings();
        var burnIn = (ds has :requiresBurnInProtection) && ds.requiresBurnInProtection;
        if (_sleep && burnIn) {
            drawLowPower(dc, clock, ds);
            return;
        }

        drawTopLine(dc);
        drawDate(dc);
        drawTime(dc, clock, ds);
        drawIndicators(dc);
    }

    // ------------------------------------------------------------------
    // Topo: bateria (acima da hora)
    // ------------------------------------------------------------------
    function drawTopLine(dc) {
        var j = Graphics.TEXT_JUSTIFY_LEFT;
        var batt = System.getSystemStats().battery;
        var bStr = "" + Math.round(batt).toNumber();
        var bColor = WHITE;
        if (batt < 15) { bColor = RED; } else if (batt < 30) { bColor = ORANGE; }
        var iw = 48;
        var wb = dc.getTextWidthInPixels(bStr, fDate);
        var wp = dc.getTextWidthInPixels("%", fUnit);
        var bBase = _h * BASE_Y - CAP_BIG - 30;
        var x = _cx - (iw + 6 + wb + 3 + wp) / 2;
        dc.drawBitmap(x, bBase - CAP_DATE / 2 - iw / 2, icBatteryTop);
        x += iw + 6;
        dc.setColor(bColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, bBase - ASC_DATE, fDate, bStr, j);
        x += wb + 3;
        dc.setColor(GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, bBase - ASC_UNIT, fUnit, "%", j);
    }

    // ------------------------------------------------------------------
    // Fundo do ecra: "SEX, 6 NOV"
    // ------------------------------------------------------------------
    function drawDate(dc) {
        var j = Graphics.TEXT_JUSTIFY_LEFT;
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dia = DIAS[(info.day_of_week - 1) % 7] + ",";
        var num = "" + info.day;
        var mes = MESES[(info.month - 1) % 12];
        var sp = 8;
        var w1 = dc.getTextWidthInPixels(dia, fDate);
        var w2 = dc.getTextWidthInPixels(num, fDate);
        var w3 = dc.getTextWidthInPixels(mes, fDate);
        var top = _h * 0.925 - ASC_DATE;
        var x = _cx - (w1 + sp + w2 + sp + w3) / 2;
        dc.setColor(WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, top, fDate, dia, j);
        x += w1 + sp;
        dc.setColor(ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, top, fDate, num, j);
        x += w2 + sp;
        dc.setColor(GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, top, fDate, mes, j);
    }

    // ------------------------------------------------------------------
    // Hora: horas e minutos em gradiente (bitmaps), sem segundos
    // ------------------------------------------------------------------
    function digit(slot, ids, n) {
        if (_digKey[slot] != n || _digBmp[slot] == null) {
            _digBmp[slot] = null;
            _digBmp[slot] = WatchUi.loadResource(ids[n]);
            _digKey[slot] = n;
        }
        return _digBmp[slot];
    }

    function drawTime(dc, clock, ds) {
        var hour = hourString(clock, ds).toNumber();
        var d0 = digit(0, H_IDS, hour / 10);
        var d1 = digit(1, H_IDS, hour % 10);
        var d2 = digit(2, M_IDS, clock.min / 10);
        var d3 = digit(3, M_IDS, clock.min % 10);
        var gap = 18;
        var total = d0.getWidth() + d1.getWidth() + gap + d2.getWidth() + d3.getWidth();
        var x = _cx - total / 2;
        var base = _h * BASE_Y;
        var top = base - DIG_H;

        dc.drawBitmap(x, top, d0);
        x += d0.getWidth();
        dc.drawBitmap(x, top, d1);
        x += d1.getWidth();
        x += gap;
        dc.drawBitmap(x, top, d2);
        x += d2.getWidth();
        dc.drawBitmap(x, top, d3);
    }

    function hourString(clock, ds) {
        var hour = clock.hour;
        if (!ds.is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }
        return hour.format("%02d");
    }

    // ------------------------------------------------------------------
    // Indicadores: recuperacao | distancia do dia
    // ------------------------------------------------------------------
    function drawIndicators(dc) {
        var row = _h * 0.765;
        var rec = getRecoveryHours();
        drawCell(dc, _cx - _w * 0.20, row, icRecovery, (rec == null) ? "--" : ("" + rec), "h", WHITE);
        var km = getDistanceKm();
        drawCell(dc, _cx + _w * 0.20, row, icDistance, (km == null) ? "--" : formatKm(km), "km", WHITE);
    }

    function drawCell(dc, cx, cy, icon, val, unit, valColor) {
        var iw = 48;
        var g1 = 8;
        var g2 = 4;
        var vw = dc.getTextWidthInPixels(val, fDate);
        var uw = dc.getTextWidthInPixels(unit, fUnit);
        var x = cx - (iw + g1 + vw + g2 + uw) / 2;
        var base = cy + CAP_DATE / 2;
        dc.drawBitmap(x, cy - iw / 2, icon);
        dc.setColor(valColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + iw + g1, base - ASC_DATE, fDate, val, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + iw + g1 + vw + g2, base - ASC_UNIT, fUnit, unit, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ------------------------------------------------------------------
    // Modo sempre-ligado (AMOLED): so hora e data, discretas e a mudar de posicao
    // ------------------------------------------------------------------
    function drawLowPower(dc, clock, ds) {
        var dx = ((clock.min % 5) - 2) * 5;
        var dy = (((clock.min / 5) % 5) - 2) * 5;
        var hs = hourString(clock, ds);
        var ms = clock.min.format("%02d");
        var wh = dc.getTextWidthInPixels(hs, fBig);
        var wm = dc.getTextWidthInPixels(ms, fBig);
        var x = _cx - (wh + 14 + wm) / 2 + dx;
        var t = _h * BASE_Y - ASC_BIG + dy;
        dc.setColor(0x505050, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, t, fBig, hs, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(x + wh + 14, t, fBig, ms, Graphics.TEXT_JUSTIFY_LEFT);
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var d = DIAS[(info.day_of_week - 1) % 7] + " " + info.day;
        var wd = dc.getTextWidthInPixels(d, fDate);
        dc.setColor(0x383838, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx - wd / 2 + dx, _h * 0.925 - ASC_DATE + dy, fDate, d, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ==================================================================
    // Dados
    // ==================================================================
    // Horas de recuperacao (aceita valor em horas ou minutos)
    function getRecoveryHours() {
        if (!(Toybox has :Complications)) { return null; }
        try {
            var c = Complications.getComplication(new Complications.Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME));
            if (c != null && c.value != null) {
                var n = c.value.toNumber();
                if (n > 96) { n = (n + 30) / 60; }
                return n;
            }
        } catch (e) {
        }
        return null;
    }

    // Distancia percorrida hoje (passos) em km
    function getDistanceKm() {
        var info = ActivityMonitor.getInfo();
        if (info == null || info.distance == null) { return null; }
        return info.distance / 100000.0;
    }

    function formatKm(f) {
        if (f >= 100.0) { return "" + Math.round(f).toNumber(); }
        var tenths = Math.round(f * 10.0).toNumber();
        return (tenths / 10) + "," + (tenths % 10);
    }
}
