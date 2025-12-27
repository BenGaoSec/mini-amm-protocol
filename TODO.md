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


---
### 2025-12-26 — Minimal Swap Closed Loop (90 min)

* [x] Docs: `docs/swap.md` presentable skeleton

  * Signature + params
  * 6-step flow
  * Revert checklist
* [x] Code: minimal `MiniAmmPair.swap()` compiles + updates reserves + emits `Swap`

  * Validate outs -> transfer out -> compute ins -> invariant check -> `_update`
* [x] Tests: 2 success + 1 revert case, all passing

**Ship criteria**

* [x] `forge test --match-path 'test/unit/pair/*Swap*.t.sol' -vv` is green

### 2025-12-27 — Pair Core Clarity: Skim / Sync / TWAP (90 min)

* [x] Re-scope: stop further swap micro-iteration (marginal ROI low); move to Pair mainline (skim/sync/TWAP)
* [x] Code: `_update()` refined

  * uint112 bounds check before narrowing
  * `uint32` timestamp compression + wrap-around behavior
  * TWAP accumulators updated using **OLD reserves** and `timeElapsed`
* [x] Docs: add execution-friendly notes for Pair maintenance + TWAP

  * Add/Update: `docs/pair.md` (or extend `docs/swap.md` with a “Pair Maintenance” section)

    * `skim(to)`: transfer **excess balances** (`balance - reserve`) to `to` (reserves unchanged)
    * `sync()`: set reserves to **current balances** (reserves updated)
    * TWAP rule: accumulate `price * dt` using **OLD reserves**, `dt=0` → no change
* [x] Tests: add core coverage for the changes

  * [x] `skim` test: transfers only excess; reserves + `blockTimestampLast` unchanged
  * [x] `sync` test: reserves become balances; `blockTimestampLast` updates
  * [x] TWAP tests: constant reserves `delta == price * dt`; `dt=0` no change (if not already green)
  * [x] Overflow test: `sync()` reverts when balances exceed `uint112` max (your `ReservesOverflow`)

**Ship criteria**

* [x] `forge test --match-path 'test/unit/pair/*{Skim,Sync,Twap}*.t.sol' -vv` is green

### Backlog — Swap V2 Fidelity Upgrade (defer; keep for later)

* [ ] Docs: turn `docs/swap.md` into an execution-friendly checklist

  * Inputs/Outputs 1-liners (`amountOut` meaning; `amountIn` inference)
  * Known V2 behaviors (no extra guards; callback optional; must repay in-tx)
  * Test matrix (exact-in, no-input revert, K revert, invalidTo)
* [ ] Code: align swap() with V2 micro-details (no new protections)

  * cache `token0/token1` locals
  * cache reserves `r0/r1` once
  * fee constants `1000` and `3` + adjusted invariant check
* [ ] Tests: “core V2 set”

  * revert: `InvalidTo`
  * revert: `InsufficientLiquidity`
  * strengthen success: `amountIn` in `Swap` event > 0 and matches expected transfer-in

---

