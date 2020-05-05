# Restarts in Julia &middot; [![Build Status](https://travis-ci.com/oddeirikigland/restarts-in-julia.svg?token=6gJVcypVU35zRus34A9v&branch=master)](https://travis-ci.com/oddeirikigland/restarts-in-julia) [![codecov](https://codecov.io/gh/oddeirikigland/restarts-in-julia/branch/master/graph/badge.svg?token=O88B2VUJPW)](https://codecov.io/gh/oddeirikigland/restarts-in-julia)

## Usage

```bash
docker build -t restarts-in-julia .
docker run restarts-in-julia
```

## Tests

```bash
julia --project -e 'using Pkg; Pkg.build(); Pkg.test(;)'
```
