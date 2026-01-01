```md
# Project Scope: Mini-AMM (V0 Baseline)

## What this project is
A UniswapV2-inspired Mini-AMM focused on a verified baseline:
- explicit scope
- reproducible test evidence
- stable iteration via test/CI gates

## Supported in V0 Baseline
### Router
- addLiquidity
- removeLiquidity
- quote
- reserve helpers (_getReserves / _sortTokens)

### Pair
- mint / burn reserve updates as required by router flows

## Not supported (explicit) in V0 Baseline
- Swaps (swapExactTokensForTokens, swapTokensForExactTokens)
- getAmountsOut / getAmountsIn
- Multi-hop routing
- Protocol fee features (feeTo/kLast/_mintFee), if applicable
- Oracle/TWAP, flash swaps, permits

## Verification approach (V0)
- Unit tests are the primary evidence.
- Repro docs under `docs/repro/` provide one-command reproduction.
- V0 baseline is complete when tests are green and a baseline tag is created.

## Baseline tag (planned)
- `amm-v0.1-baseline`
```
