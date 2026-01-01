````md
# Repro: removeLiquidity (AMM V0)

## Goal
Verify `MiniAmmRouter.removeLiquidity` for success paths and key revert gates.

## Command
```bash
forge test --match-path "*RemoveLiquidity*v0*Test*.sol" -vv
````

## Expected

* 6 tests passed
* 0 failed / 0 skipped

## Covered tests (baseline)

* testRemoveLiquidity_full_success()
* testRemoveLiquidity_partial_success()
* testRemoveLiquidity_revert_expiredDeadline()
* testRemoveLiquidity_revert_insufficientAAmount()
* testRemoveLiquidity_revert_insufficientBAmount()
* testRemoveLiquidity_revert_pairNotFound()

## What this evidence covers

* Deadline gate: `ensure(deadline)` -> Expired()
* Pair existence gate: factory.getPair == 0 -> PairNotFound()
* Slippage gates:

  * amountA < amountAMin -> InsufficientAAmount()
  * amountB < amountBMin -> InsufficientBAmount()
* Success paths: full + partial liquidity removal

## V2-style flow (6 steps)

1. Resolve pair from factory (tokenA, tokenB)
2. Sort tokens to determine token0 mapping
3. Transfer LP (pair ERC20) from user -> pair
4. Call `pair.burn(to)` to send underlying tokens to `to`
5. Map (amount0, amount1) back to (amountA, amountB)
6. Apply slippage checks (amountAMin, amountBMin)

```
::contentReference[oaicite:0]{index=0}
```
