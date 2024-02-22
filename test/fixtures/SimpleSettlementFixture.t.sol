// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    CrossMarginCashFixture,
    ActionArgs as GrappaActionArgs
} from "lib/cross-margin-engine/test/integrations-cash/CrossMarginCashFixture.t.sol";
import {
    CrossMarginPhysicalFixture,
    ActionArgs as PomaceActionArgs
} from "lib/cross-margin-engine/test/integrations-physical/CrossMarginPhysicalFixture.t.sol";

import {SimpleSettlement} from "../../src/core/SimpleSettlement.sol";
import {SimpleSettlementProxy} from "../../src/core/SimpleSettlementProxy.sol";

import {MockAuctionVault} from "../mocks/MockAuctionVault.sol";
import {MockAllowlist} from "../mocks/MockAllowList.sol";

import {ShortDurationYieldCoin} from "coins/core/coins/ShortDurationYieldCoin.sol";
import {ShortDurationYieldCoinProxy} from "coins/core/coins/ShortDurationYieldCoinProxy.sol";

import {WrappedToken} from "coins/core/coins/WrappedToken.sol";
import {WrappedTokenProxy} from "coins/core/coins/WrappedTokenProxy.sol";

import {CrossChainToken} from "coins/core/coins/CrossChainToken.sol";
import {CrossChainTokenProxy} from "coins/core/coins/CrossChainTokenProxy.sol";

import {YieldTokenAggregator} from "coins/core/oracles/YieldTokenAggregator.sol";
import {YieldTokenAggregatorProxy} from "coins/core/oracles/YieldTokenAggregatorProxy.sol";

contract SimpleSettlementCashFixture is CrossMarginCashFixture {
    SimpleSettlement internal auction;

    MockAllowlist internal allowlist;
    MockAuctionVault internal vault;

    ShortDurationYieldCoin internal sdyc;
    YieldTokenAggregator internal sdycOracle;

    WrappedToken internal hnWeth;
    CrossChainToken internal hnCCToken;

    uint8 internal hnCCTokenId;
    uint8 internal sdycId;
    uint8 internal hnWethId;

    uint256 internal sk;

    address internal auctioneer;

    constructor() CrossMarginCashFixture() {
        sk = 10101010;

        auctioneer = vm.addr(sk);
        vm.label(auctioneer, "Auctioneer");

        string memory name = "Short Duration Yield Coin";
        string memory symbol = "SDYC";

        allowlist = new MockAllowlist();

        allowlist.setAllowed(address(this), true);
        allowlist.setAllowed(address(engine), true);

        address implementation = address(new ShortDurationYieldCoin(name, symbol, 6, address(allowlist)));
        bytes memory sdycData = abi.encodeWithSelector(
            ShortDurationYieldCoin.initialize.selector,
            name,
            symbol,
            address(this),
            address(this),
            alice,
            address(0x191919),
            address(usdc)
        );

        sdyc = ShortDurationYieldCoin(address(new ShortDurationYieldCoinProxy(implementation, sdycData)));
        vm.label(address(sdyc), symbol);

        address aggImplementation = address(new YieldTokenAggregator(address(sdyc), 12, symbol));
        bytes memory aggData = abi.encodeWithSelector(YieldTokenAggregator.initialize.selector, address(this), symbol);
        sdycOracle = YieldTokenAggregator(address(new YieldTokenAggregatorProxy(aggImplementation, aggData)));

        sdyc.setOracle(address(sdycOracle));
        name = "Hn WETH";
        symbol = "hnWETH";

        address hnWethImplementation = address(new WrappedToken(name, symbol, 18, address(allowlist), address(weth)));
        bytes memory hnWethData = abi.encodeWithSelector(WrappedToken.initialize.selector, name, symbol, address(this));

        hnWeth = WrappedToken(address(new WrappedTokenProxy(hnWethImplementation, hnWethData)));
        vm.label(address(hnWeth), symbol);

        name = "Hn Cross Chain Token";
        symbol = "hnCCT";

        address hnCCTokenImplementation = address(new CrossChainToken(name, symbol, 18, address(allowlist), address(0)));
        bytes memory hnCCTokenData =
            abi.encodeWithSelector(CrossChainToken.initialize.selector, name, symbol, address(this), address(this));

        hnCCToken = CrossChainToken(address(new CrossChainTokenProxy(hnCCTokenImplementation, hnCCTokenData)));
        vm.label(address(hnCCToken), symbol);

        // register products
        sdycId = grappa.registerAsset(address(sdyc));
        hnWethId = grappa.registerAsset(address(hnWeth));
        hnCCTokenId = grappa.registerAsset(address(hnCCToken));

        pidUsdcCollat = grappa.getProductId(address(oracle), address(engine), address(weth), address(usdc), address(sdyc));
        pidEthCollat = grappa.getProductId(address(oracle), address(engine), address(weth), address(usdc), address(hnWeth));

        engine.setCollateralizable(address(weth), address(hnWeth), true);
        engine.setCollateralizable(address(usdc), address(sdyc), true);

        oracle.setSpotPrice(address(sdyc), 1 * 1e6);
        oracle.setSpotPrice(address(hnWeth), 1 * 1e6);
        oracle.setSpotPrice(address(hnCCToken), 1 * 1e6);

        address auctionImpl = address(new SimpleSettlement(address(engine), address(0x202020)));
        bytes memory auctionData = abi.encodeWithSelector(SimpleSettlement.initialize.selector, auctioneer);

        auction = SimpleSettlement(address(new SimpleSettlementProxy(auctionImpl, auctionData)));

        allowlist.setAllowed(address(auction), true);

        vm.startPrank(auctioneer);
        auction.setTokenMap(address(usdc), address(sdyc));
        auction.setTokenMap(address(weth), address(hnWeth));
        vm.stopPrank();

        vault = setUpVault();
        vm.label(address(vault), "AuctionVault");

        whitelist.setEngineAccess(address(auction), true);
        whitelist.setEngineAccess(address(vault), true);

        whitelist.setEngineAccess(alice, true);

        weth.mint(alice, 100 * 1e18);
        hnCCToken.mint(address(this), 1_000_000 * 1e18);
        hnCCToken.approve(address(engine), type(uint256).max);

        vm.startPrank(alice);
        weth.approve(address(auction), type(uint256).max);
        usdc.approve(address(auction), type(uint256).max);
        engine.setAccountAccess(address(auction), type(uint256).max);
        vm.stopPrank();
    }

    function _accountDeposit(address _account, uint8 _collateralId, uint256 _amount) internal {
        GrappaActionArgs[] memory actions = new GrappaActionArgs[](1);
        actions[0] = createAddCollateralAction(_collateralId, _account, _amount);
        engine.execute(_account, actions);
    }

    function setUpVault() internal returns (MockAuctionVault _vault) {
        _vault = new MockAuctionVault(address(engine), usdcId);
        allowlist.setAllowed(address(_vault), true);

        usdc.mint(address(_vault), 1_000_000_000 * 1e6);
        sdyc.mint(address(_vault), 1_000_000_000 * 1e6);
        hnCCToken.mint(address(_vault), 1_000_000 * 1e18);

        vm.startPrank(address(_vault));
        sdyc.approve(address(engine), type(uint256).max);
        usdc.approve(address(auction), type(uint256).max);
        hnCCToken.approve(address(auction), type(uint256).max);
        hnCCToken.approve(address(engine), type(uint256).max);
        engine.setAccountAccess(address(auction), type(uint256).max);
        vm.stopPrank();
    }
}

abstract contract SimpleSettlementPhysicalFixture is CrossMarginPhysicalFixture {
    SimpleSettlement internal auction;

    MockAllowlist internal allowlist;
    MockAuctionVault internal vault;

    ShortDurationYieldCoin internal sdyc;
    YieldTokenAggregator internal sdycOracle;

    WrappedToken internal hnWeth;

    uint8 internal sdycId;
    uint8 internal hnWethId;

    uint256 internal sk;

    address internal auctioneer;

    constructor() CrossMarginPhysicalFixture() {
        sk = 10101010;

        auctioneer = vm.addr(sk);
        vm.label(auctioneer, "Auctioneer");

        string memory name = "Short Duration Yield Coin";
        string memory symbol = "SDYC";

        allowlist = new MockAllowlist();

        allowlist.setAllowed(address(this), true);
        allowlist.setAllowed(address(engine), true);

        address implementation = address(new ShortDurationYieldCoin(name, symbol, 6, address(allowlist)));
        bytes memory sdycData = abi.encodeWithSelector(
            ShortDurationYieldCoin.initialize.selector,
            name,
            symbol,
            address(this),
            address(this),
            alice,
            address(0x191919),
            address(usdc)
        );

        sdyc = ShortDurationYieldCoin(address(new ShortDurationYieldCoinProxy(implementation, sdycData)));
        vm.label(address(sdyc), "SDYC");

        address aggImplementation = address(new YieldTokenAggregator(address(sdyc), 12, "SDYC"));
        bytes memory aggData = abi.encodeWithSelector(YieldTokenAggregator.initialize.selector, address(this), "SDYC");
        sdycOracle = YieldTokenAggregator(address(new YieldTokenAggregatorProxy(aggImplementation, aggData)));

        sdyc.setOracle(address(sdycOracle));

        name = "Hn WETH";
        symbol = "hnWETH";

        address hnWethImplementation = address(new WrappedToken(name, symbol, 18, address(allowlist), address(weth)));
        bytes memory hnWethData = abi.encodeWithSelector(WrappedToken.initialize.selector, name, symbol, address(this));

        hnWeth = WrappedToken(address(new WrappedTokenProxy(hnWethImplementation, hnWethData)));
        vm.label(address(hnWeth), "hnWETH");

        // register products
        sdycId = pomace.registerAsset(address(sdyc));
        hnWethId = pomace.registerAsset(address(hnWeth));

        pidUsdcCollat = pomace.getProductId(address(engine), address(weth), address(usdc), address(sdyc));
        pidEthCollat = pomace.getProductId(address(engine), address(weth), address(usdc), address(hnWeth));

        pomace.setCollateralizable(address(weth), address(hnWeth), true);
        pomace.setCollateralizable(address(usdc), address(sdyc), true);

        oracle.setSpotPrice(address(sdyc), 1 * 1e6);
        oracle.setSpotPrice(address(hnWeth), 1 * 1e6);

        address auctionImpl = address(new SimpleSettlement(address(0x202020), address(engine)));
        bytes memory auctionData = abi.encodeWithSelector(SimpleSettlement.initialize.selector, auctioneer);

        auction = SimpleSettlement(address(new SimpleSettlementProxy(auctionImpl, auctionData)));
        allowlist.setAllowed(address(auction), true);

        vm.startPrank(auctioneer);
        auction.setTokenMap(address(usdc), address(sdyc));
        auction.setTokenMap(address(weth), address(hnWeth));
        vm.stopPrank();

        vault = setUpVault();
        vm.label(address(vault), "AuctionVault");

        whitelist.setEngineAccess(address(auction), true);
        whitelist.setEngineAccess(address(vault), true);
        whitelist.setEngineAccess(alice, true);

        weth.mint(alice, 100 * 1e18);

        vm.startPrank(alice);
        weth.approve(address(auction), type(uint256).max);
        usdc.approve(address(auction), type(uint256).max);
        engine.setAccountAccess(address(auction), type(uint256).max);
        vm.stopPrank();
    }

    function _accountDeposit(address _account, uint8 _collateralId, uint256 _amount) internal {
        PomaceActionArgs[] memory actions = new PomaceActionArgs[](1);
        actions[0] = createAddCollateralAction(_collateralId, _account, _amount);
        engine.execute(_account, actions);
    }

    function setUpVault() internal returns (MockAuctionVault _vault) {
        _vault = new MockAuctionVault(address(engine), usdcId);
        allowlist.setAllowed(address(_vault), true);

        usdc.mint(address(_vault), 1_000_000_000 * 1e6);
        sdyc.mint(address(_vault), 1_000_000_000 * 1e6);

        vm.startPrank(address(_vault));
        sdyc.approve(address(engine), type(uint256).max);
        usdc.approve(address(auction), type(uint256).max);
        engine.setAccountAccess(address(auction), type(uint256).max);
        vm.stopPrank();
    }
}
