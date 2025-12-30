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


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

### 2025-12-28 — Router Liquidity MVP Execution Todo: ADD / REMOVE (90–120 min)

**Scope:** ERC20↔ERC20 only. Liquidity only. No swaps.

#### Hard constraints

* [ ] No ETH/WETH
* [ ] No multi-hop / path logic
* [ ] No permit / fee-on-transfer support
* [ ] Deliverables limited to:

  * [ ] `addLiquidity(...)`
  * [ ] `removeLiquidity(...)`

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

### 2025-12-29 — Router Liquidity v0: Add (First Liquidity Only) (60–90 min)

## Deliverable (DoD)

* [ ] `addLiquidity(...)` compiles
* [ ] **First-liquidity path works** (reserves `(0,0)`): uses `(amountADesired, amountBDesired)`
* [ ] Tokens go **directly** `msg.sender -> pair` (router holds **0** token balance after)
* [ ] `pair.mint(to)` returns `liquidity > 0`
* [ ] Tests: **1 success + 1 revert** green
* [ ] `forge test` fully green

## Boundaries (Decision)

* [ ] **ADD** the low-cost, invariant boundaries now (prevents foot-guns, doesn’t expand scope)
* [ ] **DEFER** reserve-based optimal quoting branch to tomorrow

## Steps (Implementation)

### 1) Add boundaries (5–10 min)

* [ ] `deadline`: revert if `block.timestamp > deadline`
* [ ] `tokenA != tokenB`
* [ ] `tokenA != address(0)` and `tokenB != address(0)`
* [ ] `to != address(0)` (recommended)
* [ ] `amountADesired > 0` and `amountBDesired > 0`
* [ ] Min checks (cheap + consistent):

  * [ ] revert if `amountADesired < amountAMin`
  * [ ] revert if `amountBDesired < amountBMin`

### 2) Pair get/create (5 min)

* [ ] `pair = factory.getPair(tokenA, tokenB)`
* [ ] if `pair == address(0)` → `pair = factory.createPair(tokenA, tokenB)`

### 3) Transfer in + mint (10–15 min)

* [ ] `transferFrom(tokenA, msg.sender, pair, amountADesired)`
* [ ] `transferFrom(tokenB, msg.sender, pair, amountBDesired)`
* [ ] `liquidity = IMiniAmmPair(pair).mint(to)`
* [ ] return `(amountADesired, amountBDesired, liquidity)`

## Tests (20–30 min)

### 1) Success

* [ ] `testAddLiquidity_firstLiquidity_success`

  * [ ] pair created
  * [ ] `liquidity > 0`
  * [ ] router token balances are 0 (optional assert, but recommended)

### 2) Revert

* [ ] `testAddLiquidity_revert_expiredDeadline`

## Finish (5 min)

* [ ] `forge fmt`
* [ ] `forge test`
* [ ] Commit: `feat(router): addLiquidity v0 first-liquidity + boundaries + minimal tests`

If you paste your Router’s existing custom errors (or confirm you use `require` strings), I’ll rewrite the “Add boundaries” block to match your exact naming conventions so the style is consistent across the repo.

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

### 2025-12-30 — RemoveLiquidity Closed Loop (60 min)

#### DoD

* [ ] `removeLiquidity()` compiles
* [ ] Tests: **2 success + 3 revert** are green
* [ ] Correct mapping `(amount0, amount1) -> (amountA, amountB)`
* [ ] Min constraints enforced (`amountA >= amountAMin`, `amountB >= amountBMin`)
* [ ] Scope stop: no permit, no fee-on, no extra features

#### Boundaries (must revert)

* [ ] Pair not found
* [ ] `amountA < amountAMin`
* [ ] `amountB < amountBMin`
* [ ] LP `transferFrom` fails (no approval / insufficient LP)
* [ ] Pair `burn` reverts (Pair-level rule)

#### Execution (ordered)

* [ ] Implement `removeLiquidity()`:

  * getPair -> sortTokens -> `pair.safeTransferFrom(msg.sender, pair, liquidity)` -> `(amount0,amount1)=pair.burn(to)` -> map to `(amountA,amountB)` -> min checks -> return
* [ ] Test: `testRemoveLiquidity_success_full`
* [ ] Test: `testRemoveLiquidity_success_partial`
* [ ] Test: `testRemoveLiquidity_revert_pairNotFound`
* [ ] Test: `testRemoveLiquidity_revert_insufficientAAmount`
* [ ] Test: `testRemoveLiquidity_revert_insufficientBAmount`
* [ ] Run tests, fix interface mismatches, rerun
* [ ] Commit: `router: removeLiquidity + tests`

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

