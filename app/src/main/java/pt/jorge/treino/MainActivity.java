package pt.jorge.treino;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.res.Configuration;
import android.graphics.Color;
import android.media.Ringtone;
import android.media.RingtoneManager;
import android.os.Handler;
import android.os.Looper;
import android.os.Bundle;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.util.Base64;
import android.view.View;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.json.JSONObject;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.zip.GZIPInputStream;

public class MainActivity extends Activity {

    private WebView web;
    private final Handler mao = new Handler(Looper.getMainLooper());
    private Runnable alarme;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        boolean escuro = (getResources().getConfiguration().uiMode
                & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES;
        int fundo = Color.parseColor(escuro ? "#000000" : "#f2f2f7");
        getWindow().setStatusBarColor(fundo);
        getWindow().setNavigationBarColor(fundo);
        if (!escuro) {
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR | View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
        }

        web = new WebView(this);
        web.setBackgroundColor(fundo);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient());
        web.addJavascriptInterface(new Ponte(), "Android");
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (web != null) {
            web.evaluateJavascript("window.aoVoltar && window.aoVoltar()", null);
        }
    }

    private void tocarAlarme() {
        try {
            Vibrator v = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
            if (v != null && v.hasVibrator()) {
                v.vibrate(VibrationEffect.createWaveform(new long[]{0, 400, 200, 400, 200, 700}, -1));
            }
        } catch (Exception e) {
            // sem vibração
        }
        try {
            Ringtone r = RingtoneManager.getRingtone(this,
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION));
            if (r != null) {
                r.play();
            }
        } catch (Exception e) {
            // sem som
        }
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("window.voltar ? window.voltar() : false", valor -> {
            if (!"true".equals(valor)) {
                finish();
            }
        });
    }

    private void devolver(final String id, final String resultado) {
        runOnUiThread(() -> web.evaluateJavascript(
                "window.__httpCb(" + JSONObject.quote(id) + "," + JSONObject.quote(resultado) + ")", null));
    }

    private class Ponte {

        @JavascriptInterface
        public void http(final String id, final String metodo, final String endereco,
                         final String chave, final String corpo) {
            new Thread(() -> {
                int estado = 0;
                String resposta;
                HttpURLConnection c = null;
                try {
                    c = (HttpURLConnection) new URL(endereco).openConnection();
                    c.setRequestMethod(metodo);
                    c.setConnectTimeout(15000);
                    c.setReadTimeout(20000);
                    String auth = Base64.encodeToString(
                            ("API_KEY:" + chave).getBytes(StandardCharsets.UTF_8), Base64.NO_WRAP);
                    c.setRequestProperty("Authorization", "Basic " + auth);
                    c.setRequestProperty("Accept", "application/json");
                    if (corpo != null && !corpo.isEmpty()) {
                        c.setDoOutput(true);
                        c.setRequestProperty("Content-Type", "application/json; charset=utf-8");
                        OutputStream os = c.getOutputStream();
                        os.write(corpo.getBytes(StandardCharsets.UTF_8));
                        os.close();
                    }
                    estado = c.getResponseCode();
                    InputStream is = estado >= 400 ? c.getErrorStream() : c.getInputStream();
                    resposta = ler(is);
                } catch (Exception e) {
                    resposta = String.valueOf(e.getMessage());
                } finally {
                    if (c != null) {
                        c.disconnect();
                    }
                }
                String json;
                try {
                    JSONObject o = new JSONObject();
                    o.put("status", estado);
                    o.put("body", resposta);
                    json = o.toString();
                } catch (Exception e) {
                    json = "{\"status\":0,\"body\":\"\"}";
                }
                devolver(id, json);
            }).start();
        }

        /** Descarrega um ficheiro binário (ex.: FIT original, comprimido em gzip) e devolve-o em base64. */
        @JavascriptInterface
        public void httpB64(final String id, final String endereco, final String chave) {
            new Thread(() -> {
                int estado = 0;
                String b64 = "";
                String erro = "";
                HttpURLConnection c = null;
                try {
                    c = (HttpURLConnection) new URL(endereco).openConnection();
                    c.setConnectTimeout(15000);
                    c.setReadTimeout(30000);
                    String auth = Base64.encodeToString(
                            ("API_KEY:" + chave).getBytes(StandardCharsets.UTF_8), Base64.NO_WRAP);
                    c.setRequestProperty("Authorization", "Basic " + auth);
                    estado = c.getResponseCode();
                    InputStream is = estado >= 400 ? c.getErrorStream() : c.getInputStream();
                    byte[] dados = lerBytes(is);
                    if (dados.length > 2 && (dados[0] & 0xff) == 0x1f && (dados[1] & 0xff) == 0x8b) {
                        dados = lerBytes(new GZIPInputStream(new ByteArrayInputStream(dados)));
                    }
                    b64 = Base64.encodeToString(dados, Base64.NO_WRAP);
                } catch (Exception e) {
                    erro = String.valueOf(e.getMessage());
                } finally {
                    if (c != null) {
                        c.disconnect();
                    }
                }
                String json;
                try {
                    JSONObject o = new JSONObject();
                    o.put("status", estado);
                    o.put("b64", b64);
                    o.put("body", erro);
                    json = o.toString();
                } catch (Exception e) {
                    json = "{\"status\":0,\"b64\":\"\",\"body\":\"\"}";
                }
                devolver(id, json);
            }).start();
        }

        @JavascriptInterface
        public void restAlarm(final int ms) {
            mao.post(() -> {
                if (alarme != null) {
                    mao.removeCallbacks(alarme);
                }
                alarme = MainActivity.this::tocarAlarme;
                mao.postDelayed(alarme, Math.max(0, ms));
            });
        }

        @JavascriptInterface
        public void cancelRestAlarm() {
            mao.post(() -> {
                if (alarme != null) {
                    mao.removeCallbacks(alarme);
                    alarme = null;
                }
            });
        }

        @JavascriptInterface
        public void vibrate(int ms) {
            Vibrator v = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
            if (v != null && v.hasVibrator()) {
                v.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE));
            }
        }

        @JavascriptInterface
        public void keepScreenOn(final boolean ligado) {
            runOnUiThread(() -> {
                if (ligado) {
                    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                } else {
                    getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
                }
            });
        }

        @JavascriptInterface
        public String version() {
            try {
                PackageInfo p = getPackageManager().getPackageInfo(getPackageName(), 0);
                return p.versionName;
            } catch (Exception e) {
                return "?";
            }
        }
    }

    private static byte[] lerBytes(InputStream is) throws Exception {
        if (is == null) {
            return new byte[0];
        }
        ByteArrayOutputStream b = new ByteArrayOutputStream();
        byte[] buf = new byte[16384];
        int n;
        while ((n = is.read(buf)) > 0) {
            b.write(buf, 0, n);
        }
        is.close();
        return b.toByteArray();
    }

    private static String ler(InputStream is) throws Exception {
        if (is == null) {
            return "";
        }
        ByteArrayOutputStream b = new ByteArrayOutputStream();
        byte[] buf = new byte[8192];
        int n;
        while ((n = is.read(buf)) > 0) {
            b.write(buf, 0, n);
        }
        is.close();
        return new String(b.toByteArray(), StandardCharsets.UTF_8);
    }
}
