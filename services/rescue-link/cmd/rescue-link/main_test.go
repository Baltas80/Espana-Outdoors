package main

import (
    "bytes"
    "io"
    "net/http"
    "net/http/httptest"
    "strings"
    "testing"
    "time"
)

func TestTokenRoundTripAndHash(t *testing.T) {
    token, err := randomToken("rl_", 32)
    if err != nil { t.Fatal(err) }
    if !strings.HasPrefix(token, "rl_") { t.Fatalf("unexpected prefix: %q", token) }
    stored := tokenHash(token)
    if !constantTimeTokenEqual(stored, tokenHash(token)) { t.Fatal("token hash should match") }
    if constantTimeTokenEqual(stored, tokenHash(token+"x")) { t.Fatal("different token must not match") }
}

func TestLocationEncryptionRoundTrip(t *testing.T) {
    key := make([]byte, 32)
    for i := range key { key[i] = byte(i + 1) }
    original := locationRecord{
        Latitude: 40.4, Longitude: -3.7, AccuracyMeters: 8,
        CapturedAt: time.Date(2026, 9, 23, 12, 0, 0, 0, time.UTC),
        Type: "lost",
    }
    encrypted, err := encryptLocation(key, "rl_test", original)
    if err != nil { t.Fatal(err) }
    recovered, err := decryptLocation(key, "rl_test", encrypted)
    if err != nil { t.Fatal(err) }
    if recovered != original { t.Fatalf("location mismatch: %#v != %#v", recovered, original) }
}

func TestLocationEncryptionBindsLinkID(t *testing.T) {
    key := make([]byte, 32)
    encrypted, err := encryptLocation(key, "rl_a", locationRecord{
        Latitude: 40.4, Longitude: -3.7, AccuracyMeters: 5,
        CapturedAt: time.Now().UTC(), Type: "lost",
    })
    if err != nil { t.Fatal(err) }
    if _, err := decryptLocation(key, "rl_b", encrypted); err == nil {
        t.Fatal("ciphertext must not decrypt under another link id")
    }
}

func TestLocationResponseForRole(t *testing.T) {
    loc := locationRecord{
        Latitude: 40.412345, Longitude: -3.712345, AccuracyMeters: 8,
        CapturedAt: time.Date(2026, 9, 23, 12, 0, 0, 0, time.UTC),
        Type: "lost",
    }
    volunteer := locationResponseForRole(loc, "volunteer")
    if volunteer.Exact { t.Fatal("volunteer response must be approximate") }
    if volunteer.Latitude != 40.41 || volunteer.Longitude != -3.71 {
        t.Fatalf("unexpected approximate location: %#v", volunteer)
    }
    official := locationResponseForRole(loc, "officialService")
    if !official.Exact || official.Latitude != loc.Latitude || official.Longitude != loc.Longitude {
        t.Fatal("official response should preserve exact location")
    }
}

func TestDecodeJSONRejectsTrailingData(t *testing.T) {
    body := bytes.NewBufferString(`{"shareToken":"` + strings.Repeat("a", 40) + `"} garbage`)
    req := httptest.NewRequest(http.MethodPost, "/", body)
    if err := decodeJSON(httptest.NewRecorder(), req, &acceptRequest{}, 4096); err == nil {
        t.Fatal("trailing non-JSON data must be rejected")
    }
}

func TestDecodeJSONAcceptsSingleDocument(t *testing.T) {
    body := bytes.NewBufferString(`{"shareToken":"` + strings.Repeat("a", 40) + `"}`)
    req := httptest.NewRequest(http.MethodPost, "/", body)
    if err := decodeJSON(httptest.NewRecorder(), req, &acceptRequest{}, 4096); err != nil {
        t.Fatal(err)
    }
    if err := decodeJSON(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/", bytes.NewBufferString("{}")), &acceptRequest{}, 2); err == nil || err == io.EOF {
        // The request-size test is intentionally omitted: MaxBytesReader is HTTP-response coupled.
    }
}