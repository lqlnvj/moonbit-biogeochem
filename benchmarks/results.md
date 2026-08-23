# Local benchmark results

Measured on 2026-08-24 in the repository working tree.

## Environment

- OS: Microsoft Windows NT 10.0.26200.0
- MoonBit: `moon 0.1.20260819`, `moonc v0.10.9+6e6c44045`, `moonrun 0.1.20260819`
- CPU: not collected because the local `Win32_Processor` query returned access denied.
- Timing method: PowerShell `Measure-Command` around the native release command.
- Raw timing log: `benchmarks/benchmark-run-2026-08-24.txt`

## Commands

```powershell
moon run cmd/benchmark --target native --release
pwsh -NoProfile -File scripts/run-benchmark.ps1 -OutputPath benchmarks/benchmark-run-2026-08-24.txt
```

## Deterministic workload output

```text
workload,solver,steps,final_metric,integral_metric
npzd,rk4,121,0.2567276354415966,44.54968446138396
coupled_carbon,rk45,4401,2110.5432848801415,41527.46184909604
```

The fixed model metrics and step counts were identical across all five runs.

## Wall-clock measurements

| Run | Native release elapsed time (ms) |
| ---: | ---: |
| 1 | 115.684 |
| 2 | 108.068 |
| 3 | 108.872 |
| 4 | 105.711 |
| 5 | 108.222 |
| Minimum | 105.711 |
| Median | 108.222 |
| Maximum | 115.684 |

These timings are machine-local observations, not performance guarantees or
cross-machine targets.
