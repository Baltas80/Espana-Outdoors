package main

import (
    "encoding/json"
    "net/http/httptest"
    "testing"
    "time"
)

func TestWriteEnvelopeEmitsClosedDataContract(t *testing.T) {
    now := time.Date(2026, 10, 5, 12, 0, 0, 0, time.UTC)
    recorder := httptest.NewRecorder()
    s := &server{}

    s.writeEnvelope(recorder, []map[string]any{
        {
            "date":                     "2026-10-05",
            "condition":                "clear",
            "min":                      10.0,
            "max":                      25.0,
            "precipitationProbability": 0.0,
            "precipitationMm":          0.0,
            "windSpeed":                12.0,
            "windDirection":            "NE",
        },
    }, now, "current")

    var envelope map[string]any
    if err := json.Unmarshal(recorder.Body.Bytes(), &envelope); err != nil {
        t.Fatalf("decode response: %v", err)
    }

    assertExactKeys(t, envelope, "data", "provenance", "freshness")

    provenance, ok := envelope["provenance"].(map[string]any)
    if !ok {
        t.Fatal("provenance is not an object")
    }
    assertExactKeys(t, provenance, "source", "licenseUrl", "observedAt")

    freshness, ok := envelope["freshness"].(map[string]any)
    if !ok {
        t.Fatal("freshness is not an object")
    }
    assertExactKeys(t, freshness, "status", "fetchedAt")

    data, ok := envelope["data"].([]any)
    if !ok || len(data) != 1 {
        t.Fatalf("unexpected data payload: %#v", envelope["data"])
    }
    record, ok := data[0].(map[string]any)
    if !ok {
        t.Fatal("data record is not an object")
    }
    assertExactKeys(
        t,
        record,
        "date",
        "condition",
        "min",
        "max",
        "precipitationProbability",
        "precipitationMm",
        "windSpeed",
        "windDirection",
    )
}

func assertExactKeys(t *testing.T, value map[string]any, expected ...string) {
    t.Helper()
    expectedSet := make(map[string]struct{}, len(expected))
    for _, key := range expected {
        expectedSet[key] = struct{}{}
    }
    if len(value) != len(expectedSet) {
        t.Fatalf("unexpected key count: got %d, want %d: %#v", len(value), len(expectedSet), value)
    }
    for key := range value {
        if _, ok := expectedSet[key]; !ok {
            t.Fatalf("unexpected field %q in %#v", key, value)
        }
    }
}
