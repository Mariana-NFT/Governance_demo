// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract InitializerEncoder {
    function encodeInitializer(
        address safe
    )
        external
        pure
        returns (
            bytes memory initParams,
            bytes memory initializer
        )
    {
        initParams = abi.encode(safe, safe, safe);

        initializer = abi.encodeWithSignature(
            "setUp(bytes)",
            initParams
        );
    }
}