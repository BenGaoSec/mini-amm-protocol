### 2025-12-26 — Minimal Swap Closed Loop (90 min)
- [x] Docs: `docs/swap.md` presentable skeleton
  - Signature + params
  - 6-step flow
  - Revert checklist
- [x] Code: minimal `MiniAmmPair.swap()` compiles + updates reserves + emits Swap
  - Validate outs -> transfer out -> compute ins -> invariant check -> _update
- [x] Tests: 2 success + 1 revert case, all passing

**Ship criteria**
- [x] `forge test --match-path 'test/unit/pair/*Swap*.t.sol' -vv` is green
