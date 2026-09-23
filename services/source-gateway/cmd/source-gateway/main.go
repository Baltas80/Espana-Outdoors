package main

import (
    "context"
    "encoding/json"
    "errors"
    "fmt"
    "io"
    "log/slog"
    "net/http"
    "net/url"
    "os"
    "os/signal"
    "strconv"
    "strings"
    "sync"
    "syscall"
    "time"

    "github.com/coreos/go-oidc/v3/oidc"
    "golang.org/x/time/rate"
)

const (
    sourceID = "aemet-weather"
    aemetAttribution = "AEMET OpenData"
    aemetLicenseURL = "https://www.aemet.es/es/datos_abiertos/AEMET_OpenData"
    keyWarningWindow = 14 * 24 * time.Hour
)

type cacheEntry struct {
    data []map[string]any
    fetchedAt time.Time
    freshUntil time.Time
    agingUntil time.Time
    staleUntil time.Time
}

type sourceHealth struct {
    status string
    observedAt time.Time
    expiresAt time.Time
    lastSuccess time.Time
    lastError string
}

type config struct {
    port string
    oidcIssuer string
    oidcAudience string
    aemetKey string
    aemetKeyExpiresAt time.Time
    aemetBaseURL string
    freshTTL time.Duration
    agingTTL time.Duration
    staleTTL time.Duration
    rateLimit rate.Limit
    rateBurst int
    clientTimeout time.Duration
}

type server struct {
    cfg config
    client *http.Client
    verifier *oidc.IDTokenVerifier
    log *slog.Logger
    cacheMu sync.RWMutex
    cache map[string]cacheEntry
    healthMu sync.RWMutex
    health sourceHealth
    limiterMu sync.Mutex
    limiters map[string]*limiterEntry
}

type limiterEntry struct {
    limiter *rate.Limiter
    lastSeen time.Time
}

func main() {
    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer stop()

    cfg, err := loadConfig(time.Now().UTC())
    if err != nil { panic(err) }

    log := slog.New(slog.NewJSONHandler(os.Stdout, nil))
    provider, err := oidc.NewProvider(ctx, cfg.oidcIssuer)
    if err != nil {
        log.Error("oidc discovery failed", "error", err)
        os.Exit(1)
    }

    s := &server{
        cfg: cfg,
        client: &http.Client{Timeout: cfg.clientTimeout},
        verifier: provider.Verifier(&oidc.Config{ClientID: cfg.oidcAudience}),
        log: log,
        cache: make(map[string]cacheEntry),
        health: sourceHealth{status: "unavailable", observedAt: time.Now().UTC()},
        limiters: make(map[string]*limiterEntry),
    }

    if until := time.Until(cfg.aemetKeyExpiresAt); until <= keyWarningWindow {
        log.Warn("AEMET API key is close to expiry", "expiresAt", cfg.aemetKeyExpiresAt)
    }

    mux := http.NewServeMux()
    mux.HandleFunc("GET /healthz", s.healthz)
    mux.HandleFunc("GET /v1/sources/{sourceID}/health", s.sourceHealth)
    mux.HandleFunc("GET /v1/sources/{sourceID}", s.sourceData)

    srv := &http.Server{
        Addr: ":" + cfg.port,
        Handler: s.securityHeaders(mux),
        ReadHeaderTimeout: 5 * time.Second,
        ReadTimeout: 20 * time.Second,
        WriteTimeout: 20 * time.Second,
        IdleTimeout: 60 * time.Second,
        MaxHeaderBytes: 16 << 10,
    }

    go func() {
        s.log.Info("source-gateway listening", "port", cfg.port)
        if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            s.log.Error("http server failed", "error", err)
            stop()
        }
    }()

    <-ctx.Done()
    shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    _ = srv.Shutdown(shutdownCtx)
}

func loadConfig(now time.Time) (config, error) {
    issuer, err := requiredEnv("OIDC_ISSUER")
    if err != nil { return config{}, err }
    audience, err := requiredEnv("OIDC_AUDIENCE")
    if err != nil { return config{}, err }
    key, err := requiredEnv("AEMET_API_KEY")
    if err != nil { return config{}, err }
    keyExpiryText, err := requiredEnv("AEMET_API_KEY_EXPIRES_AT")
    if err != nil { return config{}, err }
    keyExpiry, err := time.Parse(time.RFC3339, keyExpiryText)
    if err != nil { return config{}, fmt.Errorf("AEMET_API_KEY_EXPIRES_AT: %w", err) }
    if !keyExpiry.After(now) { return config{}, errors.New("AEMET_API_KEY_EXPIRES_AT is expired") }

    aemetBase := strings.TrimRight(envOrDefault("AEMET_BASE_URL", "https://opendata.aemet.es/opendata/api"), "/")
    parsed, err := url.Parse(aemetBase)
    if err != nil || parsed.Host == "" || parsed.Scheme != "https" {
        return config{}, errors.New("AEMET_BASE_URL must be HTTPS")
    }

    freshTTL, err := parseDuration("CACHE_FRESH_TTL", "10m")
    if err != nil { return config{}, err }
    agingTTL, err := parseDuration("CACHE_AGING_TTL", "10m")
    if err != nil { return config{}, err }
    staleTTL, err := parseDuration("CACHE_STALE_TTL", "40m")
    if err != nil { return config{}, err }
    rps, err := parseFloat("RATE_LIMIT_RPS", 2)
    if err != nil { return config{}, err }
    burst, err := parseInt("RATE_LIMIT_BURST", 10)
    if err != nil { return config{}, err }
    timeout, err := parseDuration("PROVIDER_TIMEOUT", "15s")
    if err != nil { return config{}, err }

    return config{
        port: envOrDefault("PORT", "8080"),
        oidcIssuer: strings.TrimRight(issuer, "/"),
        oidcAudience: audience,
        aemetKey: key,
        aemetKeyExpiresAt: keyExpiry,
        aemetBaseURL: aemetBase,
        freshTTL: freshTTL,
        agingTTL: agingTTL,
        staleTTL: staleTTL,
        rateLimit: rate.Limit(rps),
        rateBurst: burst,
        clientTimeout: timeout,
    }, nil
}

func requiredEnv(name string) (string, error) {
    value := strings.TrimSpace(os.Getenv(name))
    if value == "" { return "", fmt.Errorf("%s is required", name) }
    return value, nil
}

func envOrDefault(name, fallback string) string {
    if value := strings.TrimSpace(os.Getenv(name)); value != "" { return value }
    return fallback
}

func parseDuration(name, fallback string) (time.Duration, error) {
    value := envOrDefault(name, fallback)
    parsed, err := time.ParseDuration(value)
    if err != nil || parsed <= 0 { return 0, fmt.Errorf("%s must be > 0", name) }
    return parsed, nil
}

func parseInt(name string, fallback int) (int, error) {
    value := envOrDefault(name, strconv.Itoa(fallback))
    parsed, err := strconv.Atoi(value)
    if err != nil || parsed <= 0 { return 0, fmt.Errorf("%s must be > 0", name) }
    return parsed, nil
}

func parseFloat(name string, fallback float64) (float64, error) {
    value := envOrDefault(name, strconv.FormatFloat(fallback, 'f', -1, 64))
    parsed, err := strconv.ParseFloat(value, 64)
    if err != nil || parsed <= 0 { return 0, fmt.Errorf("%s must be > 0", name) }
    return parsed, nil
}

func (s *server) securityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Cache-Control", "no-store")
        w.Header().Set("Referrer-Policy", "no-referrer")
        w.Header().Set("X-Content-Type-Options", "nosniff")
        next.ServeHTTP(w, r)
    })
}

func (s *server) healthz(w http.ResponseWriter, _ *http.Request) {
    now := time.Now().UTC()
    status := "ok"
    if !s.keyUsable(now) { status = "unavailable" }
    httpStatus := http.StatusOK
    if status != "ok" { httpStatus = http.StatusServiceUnavailable }
    s.writeJSON(w, httpStatus, map[string]any{
        "status": status,
        "aemet": map[string]any{"keyExpiresAt": s.cfg.aemetKeyExpiresAt},
    })
}

func (s *server) sourceHealth(w http.ResponseWriter, r *http.Request) {
    if !s.authenticate(w, r) { return }
    if r.PathValue("sourceID") != sourceID {
        s.writeError(w, http.StatusNotFound, "source not found")
        return
    }

    s.healthMu.RLock()
    snapshot := s.health
    s.healthMu.RUnlock()

    response := map[string]any{
        "kind": "official",
        "status": snapshot.status,
        "observedAt": snapshot.observedAt,
        "licenseUrl": aemetLicenseURL,
        "attribution": aemetAttribution,
    }
    if !snapshot.expiresAt.IsZero() { response["expiresAt"] = snapshot.expiresAt }
    s.writeJSON(w, http.StatusOK, response)
}

func (s *server) sourceData(w http.ResponseWriter, r *http.Request) {
    subject, ok := s.authenticate(w, r)
    if !ok { return }
    if !s.allow(subject) {
        s.writeError(w, http.StatusTooManyRequests, "rate limit exceeded")
        return
    }
    if r.PathValue("sourceID") != sourceID {
        s.writeError(w, http.StatusNotFound, "source not found")
        return
    }

    municipalityCode := strings.TrimSpace(r.URL.Query().Get("municipalityCode"))
    if !validMunicipalityCode(municipalityCode) {
        s.writeError(w, http.StatusBadRequest, "municipalityCode must be a five-digit code")
        return
    }

    now := time.Now().UTC()
    if entry, ok := s.cacheGet(municipalityCode); ok && now.Before(entry.freshUntil) {
        s.writeEnvelope(w, entry.data, entry.fetchedAt, "current")
        return
    }

    records, err := s.fetchAemet(r.Context(), municipalityCode)
    if err == nil {
        entry := cacheEntry{
            data: records,
            fetchedAt: now,
            freshUntil: now.Add(s.cfg.freshTTL),
            agingUntil: now.Add(s.cfg.freshTTL).Add(s.cfg.agingTTL),
            staleUntil: now.Add(s.cfg.freshTTL).Add(s.cfg.agingTTL).Add(s.cfg.staleTTL),
        }
        s.cachePut(municipalityCode, entry)
        s.setHealth("healthy", now, entry.freshUntil, "")
        s.writeEnvelope(w, records, now, "current")
        return
    }

    if entry, ok := s.cacheGet(municipalityCode); ok {
        status := freshnessStatus(now, entry)
        if status != "unavailable" {
            s.setHealth("degraded", now, entry.staleUntil, err.Error())
            s.writeEnvelope(w, entry.data, entry.fetchedAt, status)
            return
        }
    }

    s.setHealth("unavailable", now, time.Time{}, err.Error())
    s.writeError(w, http.StatusServiceUnavailable, "official source unavailable")
}

func (s *server) fetchAemet(ctx context.Context, municipalityCode string) ([]map[string]any, error) {
    if !s.keyUsable(time.Now().UTC()) { return nil, errors.New("AEMET API key expired") }

    forecastURL := fmt.Sprintf("%s/prediccion/especifica/municipio/diaria/%s", s.cfg.aemetBaseURL, municipalityCode)
    envelope, err := s.getJSONWithRetry(ctx, forecastURL, map[string]string{"api_key": s.cfg.aemetKey})
    if err != nil { return nil, err }

    dataURLText, _ := envelope["datos"].(string)
    dataURL, err := url.Parse(dataURLText)
    if err != nil || dataURL.Host != "opendata.aemet.es" || dataURL.Scheme != "https" {
        return nil, errors.New("AEMET data URL rejected")
    }

    payload, err := s.getJSONWithRetry(ctx, dataURL.String(), nil)
    if err != nil { return nil, err }
    return normalizeAemet(payload)
}

func (s *server) getJSONWithRetry(ctx context.Context, rawURL string, headers map[string]string) (map[string]any, error) {
    var lastErr error
    delay := 500 * time.Millisecond

    for attempt := 1; attempt <= 3; attempt++ {
        request, err := http.NewRequestWithContext(ctx, http.MethodGet, rawURL, nil)
        if err != nil { return nil, err }
        for key, value := range headers { request.Header.Set(key, value) }

        response, err := s.client.Do(request)
        if err != nil {
            lastErr = err
        } else {
            payload, readErr := readJSONBody(response.Body)
            _ = response.Body.Close()
            if readErr == nil && response.StatusCode >= 200 && response.StatusCode < 300 {
                return payload, nil
            }
            if payload != nil {
                if message, ok := payload["descripcion"].(string); ok && message != "" {
                    lastErr = fmt.Errorf("provider HTTP %d: %s", response.StatusCode, message)
                } else {
                    lastErr = fmt.Errorf("provider HTTP %d", response.StatusCode)
                }
            } else {
                lastErr = fmt.Errorf("provider HTTP %d", response.StatusCode)
            }
            if response.StatusCode >= 400 && response.StatusCode < 500 && response.StatusCode != http.StatusTooManyRequests {
                break
            }
        }

        if attempt < 3 {
            timer := time.NewTimer(delay)
            select {
            case <-ctx.Done():
                timer.Stop()
                return nil, ctx.Err()
            case <-timer.C:
            }
            delay *= 2
        }
    }

    if lastErr == nil { lastErr = errors.New("provider request failed") }
    return nil, lastErr
}

func readJSONBody(body io.Reader) (map[string]any, error) {
    var value map[string]any
    if err := json.NewDecoder(body).Decode(&value); err != nil { return nil, err }
    return value, nil
}

func normalizeAemet(payload map[string]any) ([]map[string]any, error) {
    prediccion, ok := payload["prediccion"].(map[string]any)
    if !ok { return nil, errors.New("AEMET payload has no prediccion") }
    days, ok := prediccion["dia"].([]any)
    if !ok { return nil, errors.New("AEMET payload has no day forecast") }

    result := make([]map[string]any, 0, len(days))
    for _, raw := range days {
        day, ok := raw.(map[string]any)
        if !ok { continue }
        dateText, _ := day["fecha"].(string)
        date, err := parseAemetDate(dateText)
        if err != nil { continue }
        result = append(result, map[string]any{
            "date": date.Format("2006-01-02"),
            "condition": condition(day["estadoCielo"]),
            "min": number(day["temperatura"], "minima"),
            "max": number(day["temperatura"], "maxima"),
            "precipitationProbability": firstNumber(day["probPrecipitacion"]),
            "precipitationMm": firstNumber(day["precipitacion"]),
            "windSpeed": windSpeed(day["viento"]),
            "windDirection": windDirection(day["viento"]),
        })
    }
    if len(result) == 0 { return nil, errors.New("AEMET returned no usable forecast days") }
    return result, nil
}

func parseAemetDate(value string) (time.Time, error) {
    if parsed, err := time.Parse(time.RFC3339, value); err == nil { return parsed, nil }
    return time.Parse("2006-01-02", value)
}

func condition(value any) string {
    var text string
    if list, ok := value.([]any); ok && len(list) > 0 {
        if item, ok := list[0].(map[string]any); ok { text, _ = item["descripcion"].(string) }
    }
    normalized := strings.ToLower(text)
    switch {
    case strings.Contains(normalized, "torment"): return "storm"
    case strings.Contains(normalized, "nieve"): return "snow"
    case strings.Contains(normalized, "lluv"), strings.Contains(normalized, "precipit"): return "rain"
    case strings.Contains(normalized, "niebla"): return "fog"
    case strings.Contains(normalized, "nub") && strings.Contains(normalized, "poco"): return "partlyCloudy"
    case strings.Contains(normalized, "nub"): return "cloudy"
    case strings.Contains(normalized, "despej"): return "clear"
    default: return "unknown"
    }
}

func number(parent any, key string) any {
    object, ok := parent.(map[string]any)
    if !ok { return nil }
    return parseNumber(object[key])
}

func firstNumber(value any) any {
    switch typed := value.(type) {
    case float64:
        return typed
    case []any:
        if len(typed) == 0 { return nil }
        if item, ok := typed[0].(map[string]any); ok {
            if value := parseNumber(item["valor"]); value != nil { return value }
            if value := parseNumber(item["value"]); value != nil { return value }
        }
        return firstNumber(typed[0])
    default:
        return parseNumber(typed)
    }
}

func windSpeed(value any) any {
    if list, ok := value.([]any); ok && len(list) > 0 {
        if item, ok := list[0].(map[string]any); ok { return firstNumber(item["velocidad"]) }
    }
    return nil
}

func windDirection(value any) any {
    if list, ok := value.([]any); ok && len(list) > 0 {
        if item, ok := list[0].(map[string]any); ok {
            if direction, ok := item["direccion"].(string); ok && strings.TrimSpace(direction) != "" { return direction }
        }
    }
    return nil
}

func parseNumber(value any) any {
    switch typed := value.(type) {
    case float64:
        return typed
    case int:
        return float64(typed)
    case string:
        parsed := strings.TrimSpace(strings.ReplaceAll(typed, ",", "."))
        if parsed == "" { return nil }
        if number, err := strconv.ParseFloat(parsed, 64); err == nil { return number }
    }
    return nil
}

func validMunicipalityCode(value string) bool {
    if len(value) != 5 { return false }
    for _, char := range value {
        if char < '0' || char > '9' { return false }
    }
    return true
}

func (s *server) keyUsable(now time.Time) bool {
    return strings.TrimSpace(s.cfg.aemetKey) != "" && now.Before(s.cfg.aemetKeyExpiresAt)
}

func (s *server) cacheGet(key string) (cacheEntry, bool) {
    s.cacheMu.RLock()
    entry, ok := s.cache[key]
    s.cacheMu.RUnlock()
    return entry, ok
}

func (s *server) cachePut(key string, entry cacheEntry) {
    s.cacheMu.Lock()
    s.cache[key] = entry
    s.cacheMu.Unlock()
}

func (s *server) setHealth(status string, observedAt, expiresAt time.Time, errText string) {
    s.healthMu.Lock()
    defer s.healthMu.Unlock()
    s.health.status = status
    s.health.observedAt = observedAt
    s.health.expiresAt = expiresAt
    if status == "healthy" { s.health.lastSuccess = observedAt }
    s.health.lastError = errText
}

func (s *server) allow(subject string) bool {
    now := time.Now()
    s.limiterMu.Lock()
    defer s.limiterMu.Unlock()
    for key, entry := range s.limiters {
        if now.Sub(entry.lastSeen) > 15*time.Minute { delete(s.limiters, key) }
    }
    entry, ok := s.limiters[subject]
    if !ok {
        if len(s.limiters) >= 4096 {
            removed := 0
            for key := range s.limiters {
                delete(s.limiters, key)
                removed++
                if removed >= 256 { break }
            }
        }
        entry = &limiterEntry{limiter: rate.NewLimiter(s.cfg.rateLimit, s.cfg.rateBurst)}
        s.limiters[subject] = entry
    }
    entry.lastSeen = now
    return entry.limiter.Allow()
}

func (s *server) authenticate(w http.ResponseWriter, r *http.Request) (string, bool) {
    fields := strings.Fields(strings.TrimSpace(r.Header.Get("Authorization")))
    if len(fields) != 2 || !strings.EqualFold(fields[0], "Bearer") {
        s.writeError(w, http.StatusUnauthorized, "authentication required")
        return "", false
    }
    token, err := s.verifier.Verify(r.Context(), fields[1])
    if err != nil {
        s.writeError(w, http.StatusUnauthorized, "invalid authentication")
        return "", false
    }
    var claims map[string]any
    if err := token.Claims(&claims); err != nil { s.writeError(w, http.StatusUnauthorized, "invalid authentication"); return "", false }
    subject, _ := claims["sub"].(string)
    if strings.TrimSpace(subject) == "" { s.writeError(w, http.StatusUnauthorized, "invalid authentication"); return "", false }
    return subject, true
}

func (s *server) writeEnvelope(w http.ResponseWriter, records []map[string]any, fetchedAt time.Time, freshness string) {
    s.writeJSON(w, http.StatusOK, map[string]any{
        "data": records,
        "provenance": map[string]any{
            "source": aemetAttribution,
            "licenseUrl": aemetLicenseURL,
            "observedAt": fetchedAt,
        },
        "freshness": map[string]any{
            "status": freshness,
            "fetchedAt": fetchedAt,
        },
    })
}

func (s *server) writeJSON(w http.ResponseWriter, status int, value any) {
    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(value)
}

func (s *server) writeError(w http.ResponseWriter, status int, message string) {
    s.writeJSON(w, status, map[string]string{"error": message})
}

func freshnessStatus(now time.Time, entry cacheEntry) string {
    switch {
    case now.Before(entry.freshUntil):
        return "current"
    case now.Before(entry.agingUntil):
        return "aging"
    case now.Before(entry.staleUntil):
        return "stale"
    default:
        return "unavailable"
    }
}
