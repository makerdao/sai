pragma solidity ^0.4.8;

import "ds-roles/roles.sol";

contract SaiMom is DSRoles {
    // role identifiers
    uint8 public user = 1;

    function SaiMom(address target) {
        setRoleCapability(user, target, sig("join(uint128)"), true);
        setRoleCapability(user, target, sig("exit(uint128)"), true);
        setRoleCapability(user, target, sig("open()"), true);
        setRoleCapability(user, target, sig("shut(bytes32)"), true);
        setRoleCapability(user, target, sig("lock(bytes32,uint128)"), true);
        setRoleCapability(user, target, sig("free(bytes32,uint128)"), true);
        setRoleCapability(user, target, sig("draw(bytes32,uint128)"), true);
        setRoleCapability(user, target, sig("wipe(bytes32,uint128)"), true);
        setRoleCapability(user, target, sig("give(bytes32,address)"), true);
        setRoleCapability(user, target, sig("bite(bytes32)"), true);
        setRoleCapability(user, target, sig("boom(uint128)"), true);
        setRoleCapability(user, target, sig("bust(uint128)"), true);
        setRoleCapability(user, target, sig("cash()"), true);
        setRoleCapability(user, target, sig("bail(bytes32)"), true);
    }

    function sig(string name) constant returns (bytes4) {
        return bytes4(sha3(name));
    }

    function setUser(address who, bool enabled) auth {
        setUserRole(who, user, enabled);
    }

    function isUser(address who) constant returns (bool) {
        return hasUserRole(who, user);
    }
}
