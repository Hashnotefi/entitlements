// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

enum Role {
    Investor_MFFeederDomestic,
    Investor_MFFeederInternational,
    Investor_SDYFDomestic,
    Investor_SDYFInternational,
    Investor_LOFDomestic,
    Investor_LOFInternational,
    Investor_Reserve1,
    Investor_Reserve2,
    Investor_Reserve3,
    Investor_Reserve4,
    Investor_Reserve5,
    Custodian_Centralized,
    Custodian_Decentralized,
    System_FundAdmin,
    System_Token,
    System_Vault,
    System_Auction,
    System_Teller,
    System_Oracle,
    System_MarginEngine,
    LiquidityProvider_Options,
    LiquidityProvider_Spot,
    System_Entitlements,
    System_Messenger
}
