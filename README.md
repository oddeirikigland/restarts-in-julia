# Restarts in Julia

## Usage

```bash
docker build -t restarts-in-julia .
docker run restarts-in-julia
```

## Tests

```bash
julia --project -e 'using Pkg; Pkg.build(); Pkg.test(;)'
```
