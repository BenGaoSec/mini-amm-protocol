# Swap v1 — Execution Checklist (Uniswap V2-style)

Date: 2025-12-27

## Deliverable (DoD)

* [x] `MiniAmmPair.swap()` compiles (V2-style)
* [x] Tests: **1 success + 3 revert** are green (minimum)
* [x] Reserves updated via `_update(...)`
* [x] `Swap` event emitted

## Steps (Implementation)

### 1) Tests first (minimum set)

* [x] `testSwap_exactIn_token0ToToken1_success`
* [x] `testSwap_revert_insufficientOutput` (both outs = 0)
* [x] `testSwap_revert_insufficientInput` (no input, only output)
* [x] `testSwap_revert_kInvariant` (input too small, output too big)
* [x] `testSwap_revert_invalidTo` (`to == token0 || to == token1`)
* [x] `testSwap_revert_insufficientLiquidity` (`amountOut >= reserve`)

### 2) Implement swap() (V2 flow, no extra guards)

* [x] Load `_reserve0/_reserve1`
* [x] Validate (V2 only):

  * [x] `amount0Out > 0 || amount1Out > 0`
  * [x] `amount0Out < reserve0 && amount1Out < reserve1`
  * [x] `to != token0 && to != token1`
  * [x] **Remove:** `to != address(0)` (not V2)
* [x] Transfer out `amount0Out/amount1Out` (optimistic)
* [x] Callback if `data.length > 0`:

  * [x] `IMiniAmmCallee(to).miniAmmCall(msg.sender, amount0Out, amount1Out, data)`
* [x] Read balances `balance0/balance1`
* [x] Compute inputs from balances (V2 formula):

  * [x] `amount0In = balance0 > (reserve0 - amount0Out) ? balance0 - (reserve0 - amount0Out) : 0`
  * [x] `amount1In = balance1 > (reserve1 - amount1Out) ? balance1 - (reserve1 - amount1Out) : 0`
  * [x] require `amount0In > 0 || amount1In > 0`
* [x] Invariant check (V2 fee 0.3%):

  * [x] `balance0Adjusted = balance0 * 1000 - amount0In * 3`
  * [x] `balance1Adjusted = balance1 * 1000 - amount1In * 3`
  * [x] require `balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * 1000^2`
* [x] `_update(balance0, balance1, _reserve0, _reserve1)`
* [x] `emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to)`

### 3) Polish (keep it simple)

* [x] Keep everything inside `swap()` (no refactor)
* [x] Commit message:

  * [x] `feat(pair): implement uniswap-v2 style swap; add core tests`

## How to test

* [x] `forge test --match-path 'test/unit/pair/*Swap*.t.sol' -vv`

## Non-goals (Not today)

* [ ] Flash swap repayment math verification (deep)
* [ ] Fuzz / invariant tests
* [ ] Router integration
* [ ] Fee-on-transfer token compatibility tests
