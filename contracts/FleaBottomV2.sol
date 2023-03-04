// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ReentrancyGuard.sol';
import './EIP712.sol';
import './OrderStruct.sol';
import './Context.sol';
import './IERC721.sol';


contract FleaBottom is EIP712,ReentrancyGuard,Context{

    string constant public NAME = "FleaBottom";
    string constant public VERSION = "1.0";
    uint256 constant public INVERSE_BASIS_POIN = 10_000;


    event OrdersMatched(
        address indexed maker,
        address indexed taker,
        Order sell,
        bytes32 sellHash,
        Order buy,
        bytes32 buyHash
    );


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
        (uint256 price,uint256 tokenId,) = _canMatchOrder(sell.order, buy.order);

        //记录订单hash到filled

        cancelOrfilled[sellOrderHash] = true;
        cancelOrfilled[buyOrderHash] = true;

        //划转token
        //eth划给卖家，这里就先只收取版税，市场的交易费收取代码先不写
        _executeFundTransfer(price,sell.order.trader,buy.order.trader,sell.order.fee);
        _executeTokenTransfer(sell.order.collection, sell.order.trader, buy.order.trader, tokenId);

        emit OrdersMatched(
            buy.order.trader,
            sell.order.trader,
            sell.order,
            sellOrderHash,
            buy.order,
            buyOrderHash);
    }

    function _executeTokenTransfer(address collection,address seller,address buyer,uint256 tokenId)internal{
        IERC721(collection).safeTransferFrom(seller, buyer, tokenId);
    }

    function _executeFundTransfer(uint256 price,address seller,address buyer,Fee calldata fee) internal {
        require(msg.sender == buyer,'Cannot use ETH');
        require(msg.value >= price,'Insufficient value');
        //计算下版税
        uint256 buyerFee = price * fee.rate /INVERSE_BASIS_POIN;
        _transferTo(fee.recipient,buyerFee);
        _transferTo(seller, price - buyerFee);
    }

    function _transferTo(address to,uint256 amount)internal{
        require(to != address(0), "Transfer to zero address");
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function _canMatchOrder(Order calldata sell,Order calldata buy) internal pure returns(uint256 price,uint256 tokenId,uint256 amount){
        bool canMatch = (sell.side != buy.side
                        && sell.paymentToken == buy.paymentToken
                        && sell.collection == buy.collection
                        && sell.tokenId == buy.tokenId
                        && sell.price == buy.price
                        && sell.amount ==1
                        && buy.amount ==1);
      
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