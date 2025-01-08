# Benchmark Generator

Generates code that uses builders, for benchmarking.

Example use, from the root of this repo:

```
dart run benchmark_generator 64 JsonSerializable
```

Then change files under `plugin_torture_test/lib/` to see the refresh time.
