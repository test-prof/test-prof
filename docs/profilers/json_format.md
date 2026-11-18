# JSON reports

TestProf can emit machine-readable JSON reports — one per profiler — instead of (or along with) the human-readable stdout output. This is useful for CI analytics, editor/IDE integrations and other automated tooling that needs structured profiling data.

## Envelope

Every JSON report is a single document with a uniform envelope:

```json
{
  "profiler": "event_prof",
  "schema_version": 1,
  "test_prof_version": "1.6.4",
  "data": {}
}
```

- `profiler` — the name of the profiler (e.g. `"factory_prof"`, `"event_prof"`, `"rspec_dissect"`, `"tag_prof"`, `"factory_doctor"`, `"memory_prof"`, `"tps_prof"`).
- `schema_version` — version of the envelope format. It is bumped only when the envelope itself changes (not when a profiler-specific payload evolves).
- `test_prof_version` — version of the TestProf gem that produced the report.
- `data` — profiler-specific payload. All numeric values are raw numbers (float seconds, integer counts, bytes), never pre-formatted strings.

## Activating

Set the `TEST_PROF_FORMAT=json` environment variable to switch **all** profilers to JSON output:

```sh
TEST_PROF_FORMAT=json FPROF=1 EVENT_PROF=sql.active_record rspec ...
```

Text output remains the default; JSON is strictly opt-in.

The existing per-profiler format variables keep working and act as overrides for their profiler:

| Profiler | Override variable | Values |
|----------|-------------------|--------|
| FactoryProf | `FPROF` | `json`, `flamegraph`, `nate_heckler` |
| EventProf | `EVENT_PROF_FORMAT` | `json` |
| TagProf | `TAG_PROF_FORMAT` | `json`, `html` |
| TPSProf | `TPS_PROF_FORMAT` | `json` |

RSpecDissect, FactoryDoctor and MemoryProf are switched via the global `TEST_PROF_FORMAT=json` only.

## Report files

JSON reports are written to deterministic paths (no timestamps are added to the file names) and each write is announced with a standardized log line a consumer can grep:

```sh
[TEST PROF INFO] Report written: profiler=event_prof path=tmp/test_prof/event-prof.json
```

| Profiler | File |
|----------|------|
| FactoryProf | `tmp/test_prof/test-prof.result.json` |
| EventProf | `tmp/test_prof/event-prof.json` |
| RSpecDissect | `tmp/test_prof/rspec-dissect.json` |
| TagProf | `tmp/test_prof/tag-prof.json` |
| FactoryDoctor | `tmp/test_prof/factory-doctor.json` |
| MemoryProf | `tmp/test_prof/memory-prof.json` |
| TPSProf | `tmp/test_prof/tps-prof.json` |

## Manifest

When `TEST_PROF_FORMAT=json` is set, TestProf also writes a manifest — `tmp/test_prof/index.json` — after the test suite, listing every report written during the run:

```json
{
  "schema_version": 1,
  "test_prof_version": "1.6.4",
  "reports": [
    {"profiler": "event_prof", "path": "tmp/test_prof/event-prof.json"}
  ]
}
```

This way consumers don't have to parse stdout at all: just read the manifest.
