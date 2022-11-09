// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./strings.sol";

contract TokenPaymentSplitter {
    using SafeERC20 for IERC20;
    using strings for *;

    IERC20 private _token;

    event PaymentProcessed(string _orderId);

    address internal paymentComissionAddress;
    uint256 internal _totalTokenProcessed;
    uint256 internal _totalCommissionCollected;

    string  internal orderId;
    string  internal testAddressString;

    /*constructor(
        address _paymentComissionAddress
    ) {
        paymentComissionAddress = _paymentComissionAddress;
    }*/

    function totalTokenProcessed() public view returns (uint256) {
        return _totalTokenProcessed;
    }

    function getOrderId() public view returns (string memory) {
        return orderId;
    }

    function getPaymentComissionAddress() public view returns (address) {
        return paymentComissionAddress;
    }

    function getTestAddressString() public view returns (string memory) {
        return testAddressString;
    }

    function totalCommissionCollected() public view returns (uint256) {
        return _totalCommissionCollected;
    }

    function charge(address _chainToken, address _clientToken, uint256 _amount, string memory _orderMeta ) public virtual {
        require(
            _amount != 0,
            "TokenPaymentSplitter: account is not due payment"
        );

        strings.slice memory orderMeta = _orderMeta.toSlice();
        strings.slice memory delim = ";".toSlice();

        address merchantToken = stringToAddress(orderMeta.split(delim).toString());
        orderId = orderMeta.split(delim).toString();
        uint256 merchantAmount = _amount * 98 / 100;
        uint256 commisionAmount = _amount - merchantAmount;

        _totalTokenProcessed = _totalTokenProcessed + _amount;
        _totalCommissionCollected = _totalCommissionCollected + commisionAmount;

        IERC20(_chainToken).transferFrom(_clientToken, merchantToken, merchantAmount);
        IERC20(_chainToken).transferFrom(_clientToken, paymentComissionAddress, commisionAmount);
        
        emit PaymentProcessed(orderId);
    }

    function updatePaymentComissionAddress(address _paymentComissionAddress) public returns (address){
        require(
            paymentComissionAddress != _paymentComissionAddress,
            "TokenPaymentSplitter: account is the zero address"
        );
        paymentComissionAddress = _paymentComissionAddress;
        return paymentComissionAddress;
    }

    function stringToAddress(string memory data) internal returns(address){
        bytes memory strBytes = bytes(data);
        require(strBytes.length >= 39 && strBytes.length <= 42, "Not hex string");
        //Skip prefix
        uint start = 0;
        uint bytesBegin = 0;
        if(strBytes[1] == 'x' || strBytes[1] == 'X'){
            start = 2;
        }
        //Special case: 0xabc. should be 0x0abc
        uint160 addrValue = 0;
        uint effectPayloadLen = strBytes.length - start;
        if(effectPayloadLen == 39){
            addrValue += decode(strBytes[start++]);
            bytesBegin++;
        }
        //Main loop
        for(uint i=bytesBegin;i < 20; i++){
            addrValue <<= 8;
            uint8 tmp1 = decode(strBytes[start]);
            uint8 tmp2 = decode(strBytes[start+1]);
            uint8 combined = (tmp1 << 4) + tmp2;
            addrValue += combined;
            start+=2;
        }
        
        return address(addrValue);
    }

    //asc represents one of the char:[0-9A-Fa-f] and returns consperronding value from 0-15
    function decode(bytes1 asc) private pure returns(uint8){
        uint8 val = uint8(asc);
        //0-9
        if(val >= 48 && val <= 57){
            return val - 48;
        }
        //A-F
        if(val >= 65 && val <= 70){
            return val - 55;
        }
        //a-f
        return val - 87;
    }

}
