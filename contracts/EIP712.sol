// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Fee,Order} from "./OrderStruct.sol";

contract EIP712 {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant public FEE_TYPEHASH = keccak256(
        "Fee(uint16 rate,address recipient)"
    );

    // struct Order {
    //     address trader;//交易地址
    //     Side side;//买or卖
    //     address collection;//nft地址
    //     uint256 tokenId;
    //     uint256 amount;
    //     address paymentToken;
    //     uint256 price;
    //     uint256 listingTime;
    //     /* Order expiration timestamp - 0 for oracle cancellations. */
    //     uint256 expirationTime;
    //     Fee fee;//版税费率，版税接收地址
    // }
    bytes32 constant public ORDER_TYPEHASH = keccak256(
        "Order(address trader,uint8 side,address collection,uint256 tokenId,uint256 amount,address paymentToken,uint256 price,uint256 listingTime,uint256 expirationTime,Fee fee)"
    );

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 DOMAIN_SEPARATOR;

    function _hashDomain(EIP712Domain memory eipDomain) internal pure returns (bytes32){
        return keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eipDomain.name)),
                keccak256(bytes(eipDomain.version)),
                eipDomain.chainId,
                eipDomain.verifyingContract
            )
        );
    }

    function _hashFee(Fee calldata fee) internal pure returns(bytes32) {
        return keccak256(
            abi.encode(
                FEE_TYPEHASH,
                fee.rate,
                fee.recipient
            )
        );
    }

    /**
     * 获取order的hash
     */
    function _hashOrder(Order calldata order,uint256 nonce) internal pure returns (bytes32) {
        return keccak256(
            bytes.concat(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.trader,
                    order.side,
                    order.collection,
                    order.tokenId,
                    order.amount,
                    order.paymentToken,
                    order.price,
                    order.listingTime,
                    order.expirationTime,
                    _hashFee(order.fee)
                ),
                abi.encode(nonce)
            )
        );
    }

    /**
     * 获取待签名的订单hash
     * @param orderHash 订单hash
     */
    function _hashOrderSign(bytes32 orderHash)internal view returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                orderHash
            )
        );
    }

}