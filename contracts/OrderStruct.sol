// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;



enum Side{
    buy,sell
}

struct Fee{
    uint16 rate;
    address recipient;
}

struct Order {
    address trader;//交易地址
    Side side;//买or卖
    address collection;//nft地址
    uint256 tokenId;
    uint256 amount;
    address paymentToken;
    uint256 price;
    uint256 listingTime;
    /* Order expiration timestamp - 0 for oracle cancellations. */
    uint256 expirationTime;
    Fee fee;//版税费率，版税接收地址
}

struct Input{
    Order order;
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 blockNumber;
}
