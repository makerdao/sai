pragma solidity ^0.4.8;

import "ds-test/test.sol";
import 'ds-roles/roles.sol';
import './lpc.sol';

contract Tester {
    SaiLPC lpc;
    function Tester(SaiLPC lpc_) {
        lpc = lpc_;

        lpc.lps().approve(lpc, uint128(-1));
        lpc.ref().approve(lpc, uint128(-1));
        lpc.alt().approve(lpc, uint128(-1));
    }
    function pool(ERC20 gem, uint128 wad) {
        lpc.pool(gem, wad);
    }
    function exit(ERC20 gem, uint128 wad) {
        lpc.exit(gem, wad);
    }
    function take(ERC20 gem, uint128 wad) {
        lpc.take(gem, wad);
    }
}

contract LPCTest is DSTest, DSMath {
    ERC20   ref;
    ERC20   alt;
    DSToken lps;
    DSValue pip;
    SaiLPC  lpc;
    DSRoles mom;

    Tester   t1;
    Tester   m1;
    Tester   m2;
    Tester   m3;

    function assertEqWad(uint128 x, uint128 y) {
        assertEq(uint256(x), uint256(y));
    }

    function setRoles() {
        mom.setRoleCapability(1, address(lpc), bytes4(sha3("pool(address,uint128)")), true);
        mom.setRoleCapability(1, address(lpc), bytes4(sha3("exit(address,uint128)")), true);
        mom.setRoleCapability(1, address(lpc), bytes4(sha3("take(address,uint128)")), true);
    }

    function setUp() {
        ref = new DSTokenBase(10 ** 24);
        alt = new DSTokenBase(10 ** 24);
        lps = new DSToken('LPS', 'LPS', 18);

        pip = new DSValue();
        pip.poke(bytes32(2 ether)); // 2 refs per gem

        var gap = 1.04 ether;

        lpc = new SaiLPC(ref, alt, pip, lps);
        lpc.jump(gap);
        lps.setOwner(lpc);

        mom = new DSRoles();
        lpc.setAuthority(mom);
        mom.setRootUser(this, true);
        setRoles();

        t1 = new Tester(lpc);
        m1 = new Tester(lpc);
        m2 = new Tester(lpc);
        m3 = new Tester(lpc);

        mom.setUserRole(t1, 1, true);
        mom.setUserRole(m1, 1, true);
        mom.setUserRole(m2, 1, true);
        mom.setUserRole(m3, 1, true);

        alt.transfer(t1, 100 ether);
        ref.transfer(m1, 100 ether);
        ref.transfer(m2, 100 ether);
        ref.transfer(m3, 100 ether);
    }

    function testBasicLPC() {
        assertEqWad(lpc.per(), RAY);

        m1.pool(ref, 100 ether);
        assertEq(lps.balanceOf(m1), 100 ether);

        t1.take(ref, 50 ether);
        assertEq(ref.balanceOf(t1),  50 ether);
        assertEq(alt.balanceOf(lpc), 26 ether);
        assertEqWad(lpc.pie(), 102 ether);

        m2.pool(ref, 100 ether);
        assertEqWad(lpc.pie(), 202 ether);

        // m2 still has claim to $100 worth
        assertEqWad(rdiv(uint128(lps.balanceOf(m2)), lpc.per()), 100 ether);

        t1.take(ref, 50 ether);
        assertEqWad(lpc.pie(), 204 ether);

        pip.poke(bytes32(1 ether));  // 1 ref per gem

        m3.pool(ref, 100 ether);
        assertEqWad(lpc.pie(), 252 ether);

        // m3 has claim to $100
        assertEqWad(rdiv(uint128(lps.balanceOf(m3)), lpc.per()), 100 ether);
        // but m1, m2 have less claim each
        assertEqWad(rdiv(uint128(lps.balanceOf(m1) + lps.balanceOf(m2)), lpc.per()), 152 ether);
    }
}
