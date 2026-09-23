package main

import (
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
            t.Fatalf("validMunicipalityCode(%q) = %v, want %v", tc.value, tc.ok)
        }
    }
}
