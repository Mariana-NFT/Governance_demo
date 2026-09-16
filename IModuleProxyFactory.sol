// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IModuleProxyFactory {

    function deployModule(
        address masterCopy,
        bytes calldata initializer,
        uint256 saltNonce
    ) external returns (address proxy);
}