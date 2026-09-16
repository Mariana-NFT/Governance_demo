// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRolesSetup {
    function setUp(bytes calldata initParams) external;
}

contract RolesProxyDeployer {
    address public constant ROLES_MASTERCOPY = 0xF2964CE6161ce0e75964Fe7927cE114cb0B283D5;
    address public constant MODULE_PROXY_FACTORY = 0x000000000000aDdB49795b0f9bA5BC298cDda236;

    event ProxyDeployed(address proxy);

    function buildInitializer(address safe) public pure returns (bytes memory) {
        bytes memory initParams = abi.encode(safe, safe, safe); // owner, avatar, target — all your Safe
        return abi.encodeWithSelector(IRolesSetup.setUp.selector, initParams);
    }

    function deployRolesProxy(address safe, uint256 saltNonce) external returns (address proxy) {
        bytes memory initializer = buildInitializer(safe);

        (bool success, bytes memory returnData) = MODULE_PROXY_FACTORY.call(
            abi.encodeWithSignature(
                "deployModule(address,bytes,uint256)",
                ROLES_MASTERCOPY,
                initializer,
                saltNonce
            )
        );
        require(success, "deployModule failed");

        proxy = abi.decode(returnData, (address));
        emit ProxyDeployed(proxy);
    }
}