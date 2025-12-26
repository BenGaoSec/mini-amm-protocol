# Swap v0 — Execution Checklist
Date: 2025-12-26

## Deliverable (DoD)
- [ ] `MiniAmmPair.swap()` compiles
- [ ] Tests: 2 success + 1 revert are green
- [ ] Reserves updated via `_update(...)`
- [ ] `Swap` event emitted (recommended)

## Steps (Implementation)
1) **Add tests first**
   - [ ] `testSwap_token0ToToken1_success`
   - [ ] `testSwap_token1ToToken0_success`
   - [ ] `testSwap_revert_zeroOutput` OR `testSwap_revert_insufficientLiquidity`

2) **Implement swap() minimal flow**
   - [ ] Load `_reserve0/_reserve1`
   - [ ] Validate:
     - [ ] `amount0Out > 0 || amount1Out > 0`
     - [ ] `amount0Out < reserve0 && amount1Out < reserve1`
     - [ ] `to != address(0)`
     - [ ] (optional) `to != token0 && to != token1`
   - [ ] Transfer out `amount0Out/amount1Out`
   - [ ] (optional) callback if `data.length > 0` (do not deep-test tonight)
   - [ ] Read balances `balance0/balance1`
   - [ ] Compute inputs from balances:
     - [ ] `expected0 = reserve0 - amount0Out`
     - [ ] `expected1 = reserve1 - amount1Out`
     - [ ] `amount0In/amount1In` from post-balances
     - [ ] require `amount0In > 0 || amount1In > 0`
   - [ ] Invariant check (v0 no-fee):
     - [ ] `balance0 * balance1 >= reserve0 * reserve1`
   - [ ] `_update(balance0, balance1, _reserve0, _reserve1)`
   - [ ] `emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to)`

3) **Polish**
   - [ ] Keep v0 in one function (no refactor tonight)
   - [ ] Commit message:
     - [ ] `feat(pair): swap v0 closed loop`

## How to test
- [ ] `forge test --match-path 'test/unit/pair/*Swap*.t.sol' -vv`
- [ ] (optional) `forge test --match-path 'test/unit/pair/*.t.sol' -vv`

## Non-goals (Not tonight)
- [ ] Fee-adjusted invariant
- [ ] Fuzz / invariant tests
- [ ] Full flash swap validation
- [ ] Router integration
