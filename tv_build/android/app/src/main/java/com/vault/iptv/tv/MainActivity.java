package com.vault.iptv.tv;

import android.net.Uri;
import android.os.Bundle;
import android.os.Message;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.BridgeWebViewClient;
import java.io.ByteArrayInputStream;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

public class MainActivity extends BridgeActivity {
    private boolean adBlockClientAttached = false;

    private static final Set<String> AD_DOMAINS = new HashSet<>(Arrays.asList(
        "doubleclick.net", "googlesyndication.com", "googleadservices.com", "adservice.google.com",
        "adnxs.com", "adsrvr.org", "popads.net", "popcash.net", "propellerads.com",
        "propellerclick.com", "exoclick.com", "exosrv.com", "juicyads.com", "trafficjunky.com",
        "adsterra.com", "highperformanceformat.com", "mgid.com", "taboola.com", "outbrain.com",
        "amazon-adsystem.com", "pubmatic.com", "openx.net", "rubiconproject.com", "criteo.com",
        "criteo.net", "smartadserver.com", "bidswitch.net", "casalemedia.com", "advertising.com",
        "scorecardresearch.com", "quantserve.com", "histats.com", "mc.yandex.ru", "acscdn.com",
        "onclickalgo.com", "onclkds.com", "dolohen.com", "tsyndicate.com", "realsrv.com",
        "adsco.re", "admaven.com", "ad-maven.com", "adtng.com", "clickadu.com",
        "hilltopads.net", "monetag.com", "richpush.co", "pushengage.com", "revcontent.com",
        "zergnet.com", "teads.tv", "spotxchange.com", "springserve.com", "lijit.com",
        "sovrn.com", "sharethrough.com", "triplelift.com", "indexexchange.com", "media.net",
        "yieldmo.com", "amung.us", "statcounter.com", "hotjar.com", "clarity.ms",
        "topcreativeformat.com", "effectivegatecpm.com", "profitablegatecpm.com", "wayfarerorthodox.com",
        "bet365.com", "1xbet.com", "melbet.com", "pussl18.com", "shorte.st", "adf.ly"
    ));

    private static final String[] AD_KEYWORDS = new String[] {
        "/vast", "/vmap", "preroll", "midroll", "popunder", "popup.js",
        "adserver", "/pagead/", "/adview", "banner_ad", "clicktrack",
        "googlesyndication", "doubleclick", "adsystem", "redirect_ad", "out.php"
    };

    private static boolean isLocalAppUri(Uri uri) {
        if (uri == null) return true;
        String scheme = uri.getScheme();
        if ("about".equalsIgnoreCase(scheme) || "blob".equalsIgnoreCase(scheme) || "data".equalsIgnoreCase(scheme) || "capacitor".equalsIgnoreCase(scheme)) {
            return true;
        }
        String host = uri.getHost();
        if (host == null) return true;
        host = host.toLowerCase(Locale.ROOT);
        return host.equals("localhost") || host.equals("127.0.0.1");
    }

    private static boolean isAdRequest(Uri uri) {
        if (uri == null) return false;
        String host = uri.getHost();
        if (host == null) return false;
        host = host.toLowerCase(Locale.ROOT);

        // Never block local app or local network server
        if (host.equals("localhost") || host.equals("127.0.0.1") || host.startsWith("192.168.") || host.startsWith("10.")) {
            return false;
        }

        for (String domain : AD_DOMAINS) {
            if (host.equals(domain) || host.endsWith("." + domain)) {
                return true;
            }
        }

        String full = uri.toString().toLowerCase(Locale.ROOT);
        for (String kw : AD_KEYWORDS) {
            if (full.contains(kw)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onStart() {
        super.onStart();
        if (this.bridge != null && this.bridge.getWebView() != null) {
            WebView webView = this.bridge.getWebView();
            WebSettings settings = webView.getSettings();
            settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
            settings.setMediaPlaybackRequiresUserGesture(false);
            settings.setDomStorageEnabled(true);
            settings.setDatabaseEnabled(true);
            settings.setAllowFileAccess(true);
            settings.setAllowContentAccess(true);
            settings.setSupportMultipleWindows(false);
            settings.setJavaScriptCanOpenWindowsAutomatically(false);

            // Ensure TV remote D-pad events focus directly inside WebView
            webView.setFocusable(true);
            webView.setFocusableInTouchMode(true);
            webView.requestFocus();

            if (!adBlockClientAttached) {
                adBlockClientAttached = true;
                webView.setWebChromeClient(new WebChromeClient() {
                    @Override
                    public boolean onCreateWindow(WebView view, boolean isDialog, boolean isUserGesture, Message resultMsg) {
                        // Strictly block all ad popups / new windows
                        return false;
                    }
                });
                webView.setWebViewClient(new BridgeWebViewClient(this.bridge) {
                    @Override
                    public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                        if (request != null && isAdRequest(request.getUrl())) {
                            return new WebResourceResponse("text/plain", "utf-8", new ByteArrayInputStream(new byte[0]));
                        }
                        return super.shouldInterceptRequest(view, request);
                    }

                    @Override
                    public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                        if (request != null) {
                            Uri uri = request.getUrl();
                            if (isAdRequest(uri)) {
                                return true;
                            }
                            if (request.isForMainFrame() && !isLocalAppUri(uri)) {
                                return true;
                            }
                        }
                        return super.shouldOverrideUrlLoading(view, request);
                    }
                });
            }
        }
    }
}
