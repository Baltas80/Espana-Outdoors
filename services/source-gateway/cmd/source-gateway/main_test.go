package main

import (
    "context"
    "net/http"
    "net/http/httptest"
    "testing"
    "time"
)

func TestFreshnessStatus(t *testing.T) {
    now := time.Date(2026, 9, 23, 12, 0, 0, 0, time.UTC)
    entry := cacheEntry{
        freshUntil: now.Add(-1 * time.Minute),
        agingUntil: now.Add(9 * time.Minute),
        staleUntil: now.Add(49 * time.Minute),
    }

    if got := freshnessStatus(now, entry); got != "aging" {
        t.Fatalf("expected aging, got %s", got)
    }

    entry.agingUntil = now.Add(-1 * time.Minute)
    if got := freshnessStatus(now, entry); got != "stale" {
        t.Fatalf("expected stale, got %s", got)
    }

    entry.staleUntil = now.Add(-1 * time.Minute)
    if got := freshnessStatus(now, entry); got != "unavailable" {
        t.Fatalf("expected unavailable, got %s", got)
    }
}

func TestMunicipalityCodeValidation(t *testing.T) {
    for _, tc := range []struct {
        value string
        ok bool
    }{
        {"03099", true},
        {"1234", false},
        {"123456", false},
        {"03O99", false},
    } {
        if got := validMunicipalityCode(tc.value); got != tc.ok {
            t.Fatalf("validMunicipalityCode(%q) = %v, want %v", tc.value, got, tc.ok)
        }
    }
}


func TestGetJSONWithRetryRetriesTransientProviderFailures(t *testing.T) {
    attempts := 0
    upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        attempts++
        if attempts < 3 {
            http.Error(w, "temporary failure", http.StatusServiceUnavailable)
            return
        }
        w.Header().Set("Content-Type", "application/json")
        _, _ = w.Write([]byte(`{"ok":true}`))
    }))
    defer upstream.Close()

    s := &server{client: upstream.Client()}
    payload, err := s.getJSONWithRetry(context.Background(), upstream.URL, nil)
    if err != nil {
        t.Fatalf("getJSONWithRetry returned error: %v", err)
    }
    if got := attempts; got != 3 {
        t.Fatalf("expected 3 attempts, got %d", got)
    }
    if ok, exists := payload["ok"].(bool); !exists || !ok {
        t.Fatalf("expected successful JSON payload, got %#v", payload)
    }
}

func TestGetJSONWithRetryDoesNotRetryPermanentClientErrors(t *testing.T) {
    attempts := 0
    upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        attempts++
        http.Error(w, "bad request", http.StatusBadRequest)
    }))
    defer upstream.Close()

    s := &server{client: upstream.Client()}
    if _, err := s.getJSONWithRetry(context.Background(), upstream.URL, nil); err == nil {
        t.Fatal("expected provider error")
    }
    if attempts != 1 {
        t.Fatalf("expected one attempt for permanent client error, got %d", attempts)
    }
}
