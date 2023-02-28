// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ReentrancyGuard.sol';
import './EIP712.sol';
import './OrderStruct.sol';
import './Context.sol';


contract FleaBottom is EIP712,ReentrancyGuard,Context{

    string constant public NAME = "FleaBottom";
    string constant public VERSION = "1.0";


    constructor() {
        DOMAIN_SEPARATOR = _hashDomain(EIP712Domain({
            name: NAME,
            version: VERSION,
            chainId: block.chainid,
            verifyingContract: address(this)

        }));
    }

    mapping(bytes32 => bool) public cancelOrfilled;

    mapping(address => uint256) public nonces;

    function execute(Input calldata sell,Input calldata buy) external nonReentrant{
        //校验订单方向
        require(sell.order.side == Side.sell);

        bytes32 sellOrderHash = _hashOrder(sell.order, nonces[_msgSender()]);
        bytes32 buyOrderHash = _hashOrder(buy.order, nonces[_msgSender()]);

        //校验订单参数
        require(_validateOrder(sell.order, sellOrderHash),'Sell order has invalid parameters');
        require(_validateOrder(buy.order, buyOrderHash),'Buy order has invalid parameters');

        //校验签名
        require(_validateSignature(sell,sellOrderHash),'Sell order signature error');
        require(_validateSignature(buy,buyOrderHash),'Buy order signature error');

        //匹配订单
        (uint256 price,uint256 tokenId,uint256 amount) = _canMatchOrder(sell.order, buy.order);

        //记录订单hash到filled

        //划转token


    }

    function _canMatchOrder(Order calldata sell,Order calldata buy) internal returns(uint256 price,uint256 tokenId,uint256 amount){
        bool canMatch = (sell.side != buy.side
                        && sell.paymentToken == buy.paymentToken
                        && sell.collection == buy.collection
                        && sell.tokenId == buy.tokenId
                        && sell.price == buy.price
                        && sell.amount ==1
                        && buy.amount ==1);
        // if(sell.listingTime <= buy.listingTime){
        //     //卖方出价
        //     return

        // }else{

        // }
        require(canMatch,'Orders cannot be matched');
        return (sell.price,sell.tokenId,sell.amount);
    }

    function _validateSignature(Input calldata order,bytes32 orderHash) internal view returns(bool) {
        if(order.order.trader == _msgSender()){
            return true;
        }
        bytes32 orderSignHash = _hashOrderSign(orderHash);
        return _verify(order.order.trader, orderSignHash, order.v, order.r, order.s);
    }

    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns(bool) {
        require(v == 27 || v == 28,'Invalid v parameter');
        address recoveredSigner = ecrecover(digest, v, r, s);

        if(recoveredSigner == address(0)){
            return false;
        }else{
            return recoveredSigner == signer;
        }
    }


    function _validateOrder(Order calldata order,bytes32 orderHash)internal view returns(bool) {
        //require(order.);
        return (
            (order.trader != address(0))
            && (!cancelOrfilled[orderHash])
            && (order.listingTime < block.timestamp)
            && (order.listingTime < order.expirationTime)
            );
    }

    /**
     * 一次性取消所有当前订单
     */
    function cancelAllOrder() external {
        nonces[_msgSender()]++;
    }


}