// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PairFixture} from "test/fixtures/PairFixture.t.sol";

contract MiniAmmPair_Mint_Test is PairFixture {
    function testMintBasic() external {
        uint256 liq = _addLiquidity(alice, 1e18, 1e18);
        assertGt(liq, 0, "liq > 0");
        _assertReservesMatchBalances();
    }
}
