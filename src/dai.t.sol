pragma solidity ^0.4.18;

import "ds-test/test.sol";

import "ds-math/math.sol";

import 'ds-token/token.sol';
import 'ds-roles/roles.sol';
import 'ds-value/value.sol';

import './weth9.sol';
import './mom.sol';
import './fab.sol';
import './pit.sol';

contract TestWarp is DSNote {
    uint256  _era;

    function TestWarp() public {
        _era = now;
    }

    function era() public view returns (uint256) {
        return _era == 0 ? now : _era;
    }

    function warp(uint age) public note {
        require(_era != 0);
        _era = age == 0 ? 0 : _era + age;
    }
}

contract DevTub is DaiTub, TestWarp {
    function DevTub(
        DSToken  dai_,
        DSToken  sin_,
        DSToken  peth_,
        ERC20    gem_,
        DSToken  gov_,
        DSValue  pip_,
        DSValue  pep_,
        DaiVox   vox_,
        address  pit_
    ) public
      DaiTub(dai_, sin_, peth_, gem_, gov_, pip_, pep_, vox_, pit_) {}
}

contract DevTop is DaiTop, TestWarp {
    function DevTop(DaiTub tub_, DaiTap tap_) public DaiTop(tub_, tap_) {}
}

contract DevVox is DaiVox, TestWarp {
    function DevVox(uint par_) DaiVox(par_) public {}
}

contract DevVoxFab {
    function newVox() public returns (DevVox vox) {
        vox = new DevVox(10 ** 27);
        vox.setOwner(msg.sender);
    }
}

contract DevTubFab {
    function newTub(DSToken dai, DSToken sin, DSToken peth, DSToken gem, DSToken gov, DSValue pip, DSValue pep, DaiVox vox, address pit) public returns (DevTub tub) {
        tub = new DevTub(dai, sin, peth, gem, gov, pip, pep, vox, pit);
        tub.setOwner(msg.sender);
    }
}

contract DevTopFab {
    function newTop(DevTub tub, DaiTap tap) public returns (DevTop top) {
        top = new DevTop(tub, tap);
        top.setOwner(msg.sender);
    }
}

contract DevDadFab {
    function newDad() public returns (DSGuard dad) {
        dad = new DSGuard();
        // convenience in tests
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).dai(), bytes4(keccak256('mint(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).dai(), bytes4(keccak256('burn(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).dai(), bytes4(keccak256('mint(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).dai(), bytes4(keccak256('burn(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sin(), bytes4(keccak256('mint(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sin(), bytes4(keccak256('burn(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sin(), bytes4(keccak256('mint(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).sin(), bytes4(keccak256('burn(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).peth(), bytes4(keccak256('mint(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).peth(), bytes4(keccak256('burn(uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).peth(), bytes4(keccak256('mint(address,uint256)')));
        dad.permit(DaiFab(msg.sender).owner(), DaiFab(msg.sender).peth(), bytes4(keccak256('burn(address,uint256)')));
        dad.setOwner(msg.sender);
    }
}

contract FakePerson {
    DaiTap  public tap;
    DSToken public dai;

    function FakePerson(DaiTap _tap) public {
        tap = _tap;
        dai = tap.dai();
        dai.approve(tap);
    }

    function cash() public {
        tap.cash(dai.balanceOf(this));
    }
}

contract DaiTestBase is DSTest, DSMath {
    DevVox   vox;
    DevTub   tub;
    DevTop   top;
    DaiTap   tap;

    DaiMom   mom;

    WETH9    gem;
    DSToken  dai;
    DSToken  sin;
    DSToken  peth;
    DSToken  gov;

    GemPit   pit;

    DSValue  pip;
    DSValue  pep;
    DSRoles  dad;

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 9;
    }
    function wad(uint256 ray_) internal pure returns (uint256) {
        return wdiv(ray_, RAY);
    }

    function mark(uint price) internal {
        pip.poke(bytes32(price));
    }
    function mark(DSToken tkn, uint price) internal {
        if (address(tkn) == address(gov)) pep.poke(bytes32(price));
        else if (address(tkn) == address(gem)) mark(price);
    }
    function warp(uint256 age) internal {
        vox.warp(age);
        tub.warp(age);
        top.warp(age);
    }

    function setUp() public {
        GemFab gemFab = new GemFab();
        DevVoxFab voxFab = new DevVoxFab();
        DevTubFab tubFab = new DevTubFab();
        TapFab tapFab = new TapFab();
        DevTopFab topFab = new DevTopFab();
        MomFab momFab = new MomFab();
        DevDadFab dadFab = new DevDadFab();

        DaiFab daiFab = new DaiFab(gemFab, VoxFab(voxFab), TubFab(tubFab), tapFab, TopFab(topFab), momFab, DadFab(dadFab));

        gem = new WETH9();
        gem.deposit.value(100 ether)();
        gov = new DSToken('GOV');
        pip = new DSValue();
        pep = new DSValue();
        pit = new GemPit();

        daiFab.makeTokens();
        daiFab.makeVoxTub(ERC20(gem), gov, pip, pep, pit);
        daiFab.makeTapTop();
        daiFab.configParams();
        daiFab.verifyParams();
        DSRoles authority = new DSRoles();
        authority.setRootUser(this, true);
        daiFab.configAuth(authority);

        dai = DSToken(daiFab.dai());
        sin = DSToken(daiFab.sin());
        peth = DSToken(daiFab.peth());
        vox = DevVox(daiFab.vox());
        tub = DevTub(daiFab.tub());
        tap = DaiTap(daiFab.tap());
        top = DevTop(daiFab.top());
        mom = DaiMom(daiFab.mom());
        dad = DSRoles(daiFab.dad());

        dai.approve(tub);
        peth.approve(tub);
        gem.approve(tub, uint(-1));
        gov.approve(tub);

        dai.approve(tap);
        peth.approve(tap);

        mark(1 ether);
        mark(gov, 1 ether);

        mom.setCap(20 ether);
        mom.setAxe(ray(1 ether));
        mom.setMat(ray(1 ether));
        mom.setTax(ray(1 ether));
        mom.setFee(ray(1 ether));
        mom.setTubGap(1 ether);
        mom.setTapGap(1 ether);
    }
}

contract DaiTubTest is DaiTestBase {
    function testBasic() public {
        assertEq( peth.balanceOf(tub), 0 ether );
        assertEq( peth.balanceOf(this), 0 ether );
        assertEq( gem.balanceOf(tub), 0 ether );

        // edge case
        assertEq( uint256(tub.per()), ray(1 ether) );
        tub.join(10 ether);
        assertEq( uint256(tub.per()), ray(1 ether) );

        assertEq( peth.balanceOf(this), 10 ether );
        assertEq( gem.balanceOf(tub), 10 ether );
        // price formula
        tub.join(10 ether);
        assertEq( uint256(tub.per()), ray(1 ether) );
        assertEq( peth.balanceOf(this), 20 ether );
        assertEq( gem.balanceOf(tub), 20 ether );

        var cup = tub.open();

        assertEq( peth.balanceOf(this), 20 ether );
        assertEq( peth.balanceOf(tub), 0 ether );
        tub.lock(cup, 10 ether); // lock peth token
        assertEq( peth.balanceOf(this), 10 ether );
        assertEq( peth.balanceOf(tub), 10 ether );

        assertEq( dai.balanceOf(this), 0 ether);
        tub.draw(cup, 5 ether);
        assertEq( dai.balanceOf(this), 5 ether);


        assertEq( dai.balanceOf(this), 5 ether);
        tub.wipe(cup, 2 ether);
        assertEq( dai.balanceOf(this), 3 ether);

        assertEq( dai.balanceOf(this), 3 ether);
        assertEq( peth.balanceOf(this), 10 ether );
        tub.shut(cup);
        assertEq( dai.balanceOf(this), 0 ether);
        assertEq( peth.balanceOf(this), 20 ether );
    }
    function testGive() public {
        var cup = tub.open();
        assertEq(tub.lad(cup), this);

        address ali = 0x456;
        tub.give(cup, ali);
        assertEq(tub.lad(cup), ali);
    }
    function testFailGiveNotLad() public {
        var cup = tub.open();
        address ali = 0x456;
        tub.give(cup, ali);

        address bob = 0x789;
        tub.give(cup, bob);
    }
    function testMold() public {
        var setAxe = bytes4(keccak256('setAxe(uint256)'));
        var setCap = bytes4(keccak256('setCap(uint256)'));
        var setMat = bytes4(keccak256('setMat(uint256)'));

        assertTrue(mom.call(setCap, 0 ether));
        assertTrue(mom.call(setCap, 5 ether));

        assertTrue(!mom.call(setAxe, ray(2 ether)));
        assertTrue( mom.call(setMat, ray(2 ether)));
        assertTrue( mom.call(setAxe, ray(2 ether)));
        assertTrue(!mom.call(setMat, ray(1 ether)));
    }
    function testTune() public {
        assertEq(vox.how(), 0);
        mom.setHow(2 * 10 ** 25);
        assertEq(vox.how(), 2 * 10 ** 25);
    }
    function testPriceFeedSetters() public {
        var setPip = bytes4(keccak256('setPip(address)'));
        var setPep = bytes4(keccak256('setPep(address)'));
        var setVox = bytes4(keccak256('setVox(address)'));

        assertTrue(tub.pip() != address(0x1));
        assertTrue(tub.pep() != address(0x2));
        assertTrue(tub.vox() != address(0x3));
        assertTrue(mom.call(setPip, address(0x1)));
        assertTrue(mom.call(setPep, address(0x2)));
        assertTrue(mom.call(setVox, address(0x3)));
        assertTrue(tub.pip() == address(0x1));
        assertTrue(tub.pep() == address(0x2));
        assertTrue(tub.vox() == address(0x3));
    }
    function testJoinInitial() public {
        assertEq(peth.totalSupply(),     0 ether);
        assertEq(peth.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
        tub.join(10 ether);
        assertEq(peth.balanceOf(this), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),  10 ether);
    }
    function testJoinExit() public {
        assertEq(peth.balanceOf(this), 0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
        tub.join(10 ether);
        assertEq(peth.balanceOf(this), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),  10 ether);

        tub.exit(5 ether);
        assertEq(peth.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 95 ether);
        assertEq(gem.balanceOf(tub),   5 ether);

        tub.join(2 ether);
        assertEq(peth.balanceOf(this),  7 ether);
        assertEq(gem.balanceOf(this), 93 ether);
        assertEq(gem.balanceOf(tub),   7 ether);

        tub.exit(1 ether);
        assertEq(peth.balanceOf(this),  6 ether);
        assertEq(gem.balanceOf(this), 94 ether);
        assertEq(gem.balanceOf(tub),   6 ether);
    }
    function testFailOverDraw() public {
        mom.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 11 ether);
    }
    function testFailOverDrawExcess() public {
        mom.setMat(ray(1 ether));
        tub.join(20 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 11 ether);
    }
    function testDraw() public {
        mom.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        assertEq(dai.balanceOf(this),  0 ether);
        tub.draw(cup, 10 ether);
        assertEq(dai.balanceOf(this), 10 ether);
    }
    function testWipe() public {
        mom.setMat(ray(1 ether));
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);

        assertEq(dai.balanceOf(this), 10 ether);
        tub.wipe(cup, 5 ether);
        assertEq(dai.balanceOf(this),  5 ether);
    }
    function testUnsafe() public {
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 9 ether);

        assertTrue(tub.safe(cup));
        mark(1 ether / 2);
        assertTrue(!tub.safe(cup));
    }
    function testBiteUnderParity() public {
        assertEq(uint(tub.axe()), uint(ray(1 ether)));  // 100% collateralisation limit
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);           // 200% collateralisation
        mark(1 ether / 4);                // 50% collateralisation

        assertEq(tap.fog(), uint(0));
        tub.bite(cup);
        assertEq(tap.fog(), uint(10 ether));
    }
    function testBiteOverParity() public {
        mom.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 4 ether);  // 250% collateralisation
        assertTrue(tub.safe(cup));
        mark(1 ether / 2);       // 125% collateralisation
        assertTrue(!tub.safe(cup));

        assertEq(tub.din(),    4 ether);
        assertEq(tub.tab(cup), 4 ether);
        assertEq(tap.fog(),    0 ether);
        assertEq(tap.woe(),    0 ether);
        tub.bite(cup);
        assertEq(tub.din(),    0 ether);
        assertEq(tub.tab(cup), 0 ether);
        assertEq(tap.fog(),    8 ether);
        assertEq(tap.woe(),    4 ether);

        // cdp should now be safe with 0 dai debt and 2 peth remaining
        var peth_before = peth.balanceOf(this);
        tub.free(cup, 1 ether);
        assertEq(peth.balanceOf(this) - peth_before, 1 ether);
    }
    function testLock() public {
        tub.join(10 ether);
        var cup = tub.open();

        assertEq(peth.balanceOf(tub),  0 ether);
        tub.lock(cup, 10 ether);
        assertEq(peth.balanceOf(tub), 10 ether);
    }
    function testFree() public {
        mom.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 4 ether);  // 250% collateralisation

        var peth_before = peth.balanceOf(this);
        tub.free(cup, 2 ether);  // 225%
        assertEq(peth.balanceOf(this) - peth_before, 2 ether);
    }
    function testFailFreeToUnderCollat() public {
        mom.setMat(ray(2 ether));  // require 200% collateralisation
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 4 ether);  // 250% collateralisation

        tub.free(cup, 3 ether);  // 175% -- fails
    }
    function testFailDrawOverDebtCeiling() public {
        mom.setCap(4 ether);
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 5 ether);
    }
    function testDebtCeiling() public {
        mom.setCap(5 ether);
        mom.setMat(ray(2 ether));  // require 200% collat
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        tub.draw(cup, 5 ether);          // 200% collat, full debt ceiling
        mark(1 ether / 2);  // 100% collat

        assertEq(tub.air(), uint(10 ether));
        assertEq(tap.fog(), uint(0 ether));
        tub.bite(cup);
        assertEq(tub.air(), uint(0 ether));
        assertEq(tap.fog(), uint(10 ether));

        tub.join(10 ether);
        // peth hasn't been diluted yet so still 1:1 peth:gem
        assertEq(peth.balanceOf(this), 10 ether);
    }
}

contract CageTest is DaiTestBase {
    // ensure cage sets the settle prices right
    function cageSetup() public returns (bytes32) {
        mom.setCap(5 ether);            // 5 dai debt ceiling
        mark(1 ether);   // price 1:1 gem:ref
        mom.setMat(ray(2 ether));       // require 200% collat
        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 5 ether);       // 200% collateralisation

        return cup;
    }
    function testCageSafeOverCollat() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tap.woe(), 0);         // no bad debt
        assertEq(tub.pie(), 10 ether);

        tub.join(20 ether);   // give us some more peth
        mark(1 ether);
        top.cage();

        assertEq(tub.din(),      5 ether);  // debt remains in tub
        assertEq(wad(top.fix()), 1 ether);  // dai redeems 1:1 with gem
        assertEq(wad(tub.fit()), 1 ether);  // peth redeems 1:1 with gem just before pushing gem to tub

        assertEq(gem.balanceOf(tap),  5 ether);  // saved for dai
        assertEq(gem.balanceOf(tub), 25 ether);  // saved for peth
    }
    function testCageUnsafeOverCollat() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more peth
        var price = wdiv(3 ether, 4 ether);
        mark(price);
        top.cage();        // 150% collat

        assertEq(top.fix(), rdiv(1 ether, price));  // dai redeems 4:3 with gem
        assertEq(tub.fit(), ray(price));                 // peth redeems 1:1 with gem just before pushing gem to tub

        // gem needed for dai is 5 * 4 / 3
        var saved = rmul(5 ether, rdiv(WAD, price));
        assertEq(gem.balanceOf(tap),  saved);             // saved for dai
        assertEq(gem.balanceOf(tub),  30 ether - saved);  // saved for peth
    }
    function testCageAtCollat() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(top.fix(), ray(2 ether));  // dai redeems 1:2 with gem, 1:1 with ref
        assertEq(tub.per(), 0);       // peth redeems 1:0 with gem after cage
    }
    function testCageAtCollatFreePeth() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more peth
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(top.fix(), ray(2 ether));  // dai redeems 1:2 with gem, 1:1 with ref
        assertEq(tub.fit(), ray(price));       // peth redeems 1:1 with gem just before pushing gem to tub
    }
    function testCageUnderCollat() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(2 * dai.totalSupply(), gem.balanceOf(tap));
        assertEq(top.fix(), ray(2 ether));  // dai redeems 1:2 with gem, 2:1 with ref
        assertEq(tub.per(), 0);       // peth redeems 1:0 with gem after cage
    }
    function testCageUnderCollatFreePeth() public {
        cageSetup();

        assertEq(top.fix(), 0);
        assertEq(tub.fit(), 0);
        assertEq(tub.per(), ray(1 ether));

        tub.join(20 ether);   // give us some more peth
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(4 * dai.totalSupply(), gem.balanceOf(tap));
        assertEq(top.fix(), ray(4 ether));                 // dai redeems 1:4 with gem, 1:1 with ref
    }

    function testCageNoDai() public {
        var cup = cageSetup();
        tub.wipe(cup, 5 ether);
        assertEq(dai.totalSupply(), 0);

        top.cage();
        assertEq(top.fix(), ray(1 ether));
    }
    function testMock() public {
        cageSetup();
        top.cage();

        gem.deposit.value(1000 ether)();
        gem.approve(tap, uint(-1));
        tap.mock(1000 ether);
        assertEq(dai.balanceOf(this), 1005 ether);
        assertEq(gem.balanceOf(tap),  1005 ether);
    }
    function testMockNoDai() public {
        var cup = cageSetup();
        tub.wipe(cup, 5 ether);
        assertEq(dai.totalSupply(), 0);

        top.cage();

        gem.deposit.value(1000 ether)();
        gem.approve(tap, uint(-1));
        tap.mock(1000 ether);
        assertEq(dai.balanceOf(this), 1000 ether);
        assertEq(gem.balanceOf(tap),  1000 ether);
    }

    // ensure cash returns the expected amount
    function testCashSafeOverCollat() public {
        var cup = cageSetup();
        mark(1 ether);
        top.cage();

        assertEq(dai.balanceOf(this),  5 ether);
        assertEq(peth.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(gem.balanceOf(tub),   5 ether);
        assertEq(gem.balanceOf(tap),   5 ether);

        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this),   0 ether);
        assertEq(peth.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this),  95 ether);
        assertEq(gem.balanceOf(tub),    5 ether);

        assertEq(tub.ink(cup), 10 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 5 ether);
        tub.free(cup, tub.ink(cup));
        assertEq(peth.balanceOf(this),   5 ether);
        tap.vent();
        top.flow();
        tub.exit(uint256(peth.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(peth.totalSupply(), 0);
    }
    function testCashSafeOverCollatWithFreePeth() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more peth
        mark(1 ether);
        top.cage();

        assertEq(dai.balanceOf(this),  5 ether);
        assertEq(peth.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        assertEq(gem.balanceOf(tub),  25 ether);
        assertEq(gem.balanceOf(tap),   5 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        assertEq(peth.balanceOf(this), 25 ether);
        tap.cash(dai.balanceOf(this));
        tub.exit(uint256(peth.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(dai.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
        assertEq(dai.totalSupply(), 0);
        assertEq(peth.totalSupply(), 0);
    }
    function testFailCashSafeOverCollatWithFreePethExitBeforeBail() public {
        // fails because exit is before bail
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more peth
        mark(1 ether);
        top.cage();

        tap.cash(dai.balanceOf(this));
        tub.exit(uint256(peth.balanceOf(this)));
        assertEq(peth.balanceOf(this), 0 ether);
        uint256 gemByDAI = 5 ether; // Adding 5 gem from 5 dai
        uint256 gemByPETH = wdiv(wmul(20 ether, 30 ether - gemByDAI), 30 ether);
        assertEq(gem.balanceOf(this), 70 ether + gemByDAI + gemByPETH);

        assertEq(dai.balanceOf(this), 0);
        assertEq(dai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        assertEq(peth.balanceOf(this), 5 ether); // peth retrieved by bail(cup)

        tub.exit(uint256(peth.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(dai.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        assertEq(dai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        assertEq(peth.totalSupply(), 0);
    }
    function testCashUnsafeOverCollat() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more peth
        var price = wdiv(3 ether, 4 ether);
        mark(price);
        top.cage();        // 150% collat

        assertEq(dai.balanceOf(this),  5 ether);
        assertEq(peth.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);

        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this),   0 ether);
        assertEq(peth.balanceOf(this),  20 ether);

        uint256 gemByDAI = wdiv(wmul(5 ether, 4 ether), 3 ether);
        uint256 gemByPETH = 0;

        assertEq(gem.balanceOf(this), 70 ether + gemByDAI + gemByPETH);
        assertEq(gem.balanceOf(tub),  30 ether - gemByDAI - gemByPETH);

        // how much gem should be returned?
        // there were 10 gems initially, of which 5 were 100% collat
        // at the cage price, 5 * 4 / 3 are 100% collat,
        // leaving 10 - 5 * 4 / 3 as excess = 3.333
        // this should all be returned
        var ink = tub.ink(cup);
        var tab = tub.tab(cup);
        var pethToRecover = sub(ink, wdiv(tab, price));
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));

        assertEq(peth.balanceOf(this), 20 ether + pethToRecover);
        assertEq(peth.balanceOf(tub),  0 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(peth.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
        assertEq(peth.totalSupply(), 0);
        assertEq(dai.totalSupply(), 0);
    }
    function testCashAtCollat() public {
        var cup = cageSetup();
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(dai.balanceOf(this),  5 ether);
        assertEq(peth.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this),   0 ether);
        assertEq(peth.balanceOf(this),   0 ether);

        var saved = rmul(5 ether, rdiv(WAD, price));

        assertEq(gem.balanceOf(this),  90 ether + saved);
        assertEq(gem.balanceOf(tub),   10 ether - saved);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
        assertEq(peth.totalSupply(), 0);
        assertEq(dai.totalSupply(), 0);
    }
    function testCashAtCollatFreePeth() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more peth
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(dai.balanceOf(this),   5 ether);
        assertEq(peth.balanceOf(this),  20 ether);
        assertEq(gem.balanceOf(this),  70 ether);

        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this),   0 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        top.flow();
        tub.exit(uint256(peth.balanceOf(this)));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(peth.totalSupply(), 0);
    }
    function testFailCashAtCollatFreePethExitBeforeBail() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more peth
        var price = wdiv(1 ether, 2 ether);  // 100% collat
        mark(price);
        top.cage();

        assertEq(dai.balanceOf(this),  5 ether);
        assertEq(peth.balanceOf(this), 20 ether);
        assertEq(gem.balanceOf(this), 70 ether);

        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this),   0 ether);
        tub.exit(uint256(peth.balanceOf(this)));
        assertEq(peth.balanceOf(this),   0 ether);


        var gemByDAI = wmul(5 ether, 2 ether);
        var gemByPETH = wdiv(wmul(20 ether, 30 ether - gemByDAI), 30 ether);

        assertEq(gem.balanceOf(this), 70 ether + gemByDAI + gemByPETH);
        assertEq(gem.balanceOf(tub),  30 ether - gemByDAI - gemByPETH);

        assertEq(dai.totalSupply(), 0);
        assertEq(sin.totalSupply(), 0);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        tap.vent();
        tub.exit(uint256(peth.balanceOf(this)));

        // Cup did not have peth to free, then the ramaining gem in tub can not be shared as there is not more peth to exit
        assertEq(gem.balanceOf(this), 70 ether + gemByDAI + gemByPETH);
        assertEq(gem.balanceOf(tub),  30 ether - gemByDAI - gemByPETH);

        assertEq(peth.totalSupply(), 0);
    }
    function testCashUnderCollat() public {
        var cup = cageSetup();
        var price = wdiv(1 ether, 4 ether);  // 50% collat
        mark(price);
        top.cage();

        assertEq(dai.balanceOf(this),  5 ether);
        assertEq(peth.balanceOf(this),  0 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this),   0 ether);
        assertEq(peth.balanceOf(this),   0 ether);

        // get back all 10 gems, which are now only worth 2.5 ref
        // so you've lost 50% on you dai
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        // how much gem should be returned?
        // none :D
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        tap.vent();
        assertEq(peth.totalSupply(), 0);
        assertEq(dai.totalSupply(), 0);
    }
    function testCashUnderCollatFreePeth() public {
        var cup = cageSetup();
        tub.join(20 ether);   // give us some more peth
        var price = wdiv(1 ether, 4 ether);   // 50% collat
        mark(price);
        top.cage();

        assertEq(dai.balanceOf(this),  5 ether);
        assertEq(gem.balanceOf(this), 70 ether);
        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this),  0 ether);
        // returns 20 gems, taken from the free peth,
        // dai is made whole
        assertEq(gem.balanceOf(this), 90 ether);

        assertEq(peth.balanceOf(this),  20 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));

        tap.vent();
        top.flow();
        tub.exit(uint256(peth.balanceOf(this)));
        assertEq(peth.balanceOf(this),   0 ether);
        // the peth has taken a 50% loss - 10 gems returned from 20 put in
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(gem.balanceOf(tub),    0 ether);

        assertEq(dai.totalSupply(), 0);
        assertEq(peth.totalSupply(), 0);
    }
    function testCashSafeOverCollatAndMock() public {
        testCashSafeOverCollat();
        gem.approve(tap, uint(-1));
        tap.mock(5 ether);
        assertEq(dai.balanceOf(this), 5 ether);
        assertEq(gem.balanceOf(this), 95 ether);
        assertEq(gem.balanceOf(tap), 5 ether);
    }
    function testCashSafeOverCollatWithFreePethAndMock() public {
        testCashSafeOverCollatWithFreePeth();
        gem.approve(tap, uint(-1));
        tap.mock(5 ether);
        assertEq(dai.balanceOf(this), 5 ether);
        assertEq(gem.balanceOf(this), 95 ether);
        assertEq(gem.balanceOf(tap), 5 ether);
    }
    function testFailCashSafeOverCollatWithFreePethExitBeforeBailAndMock() public {
        testFailCashSafeOverCollatWithFreePethExitBeforeBail();
        gem.approve(tap, uint(-1));
        tap.mock(5 ether);
        assertEq(dai.balanceOf(this), 5 ether);
        assertEq(gem.balanceOf(this), 95 ether);
        assertEq(gem.balanceOf(tap), 5 ether);
    }

    function testThreeCupsOverCollat() public {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more peth
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(peth.balanceOf(this), 50 ether); // free peth
        assertEq(peth.balanceOf(tub), 50 ether); // locked peth

        uint256 price = 1 ether;
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 5 ether); // Needed to payout 5 dai
        assertEq(gem.balanceOf(tub), 95 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // 5 peth recovered, and 5 peth burnt

        assertEq(peth.balanceOf(this), 55 ether); // free peth
        assertEq(peth.balanceOf(tub), 40 ether); // locked peth

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 peth recovered

        assertEq(peth.balanceOf(this), 75 ether); // free peth
        assertEq(peth.balanceOf(tub), 20 ether); // locked peth

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 peth recovered

        assertEq(peth.balanceOf(this), 95 ether); // free peth
        assertEq(peth.balanceOf(tub), 0); // locked peth

        tap.cash(dai.balanceOf(this));

        assertEq(dai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 5 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(peth.balanceOf(this))); // exit 95 peth at price 95/95

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(peth.totalSupply(), 0);
    }
    function testThreeCupsAtCollat() public {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more peth
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(peth.balanceOf(this), 50 ether); // free peth
        assertEq(peth.balanceOf(tub), 50 ether); // locked peth

        var price = wdiv(1 ether, 2 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 10 ether); // Needed to payout 10 dai
        assertEq(gem.balanceOf(tub), 90 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // 10 peth burnt

        assertEq(peth.balanceOf(this), 50 ether); // free peth
        assertEq(peth.balanceOf(tub), 40 ether); // locked peth

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 peth recovered

        assertEq(peth.balanceOf(this), 70 ether); // free peth
        assertEq(peth.balanceOf(tub), 20 ether); // locked peth

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 peth recovered

        assertEq(peth.balanceOf(this), 90 ether); // free peth
        assertEq(peth.balanceOf(tub), 0); // locked peth

        tap.cash(dai.balanceOf(this));

        assertEq(dai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 10 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(peth.balanceOf(this))); // exit 90 peth at price 90/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(peth.totalSupply(), 0);
    }
    function testThreeCupsUnderCollat() public {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more peth
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(peth.balanceOf(this), 50 ether); // free peth
        assertEq(peth.balanceOf(tub), 50 ether); // locked peth

        var price = wdiv(1 ether, 4 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 20 ether); // Needed to payout 5 dai
        assertEq(gem.balanceOf(tub), 80 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // No peth is retrieved as the cup doesn't even cover the debt. 10 locked peth in cup are burnt from tub

        assertEq(peth.balanceOf(this), 50 ether); // free peth
        assertEq(peth.balanceOf(tub), 40 ether); // locked peth

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 peth recovered

        assertEq(peth.balanceOf(this), 70 ether); // free peth
        assertEq(peth.balanceOf(tub), 20 ether); // locked peth

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 peth recovered

        assertEq(peth.balanceOf(this), 90 ether); // free peth
        assertEq(peth.balanceOf(tub), 0); // locked peth

        tap.cash(dai.balanceOf(this));

        assertEq(dai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 20 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(peth.balanceOf(this))); // exit 90 peth at price 80/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(peth.totalSupply(), 0);
    }
    function testThreeCupsPETHZeroValue() public {
        var cup = cageSetup();
        tub.join(90 ether);   // give us some more peth
        var cup2 = tub.open(); // open a new cup
        tub.lock(cup2, 20 ether); // lock collateral but not draw DAI
        var cup3 = tub.open(); // open a new cup
        tub.lock(cup3, 20 ether); // lock collateral but not draw DAI

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 100 ether);
        assertEq(gem.balanceOf(this), 0);
        assertEq(peth.balanceOf(this), 50 ether); // free peth
        assertEq(peth.balanceOf(tub), 50 ether); // locked peth

        var price = wdiv(1 ether, 20 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), 100 ether); // Needed to payout 5 dai
        assertEq(gem.balanceOf(tub), 0 ether);

        tub.bite(cup);
        tub.free(cup, tub.ink(cup)); // No peth is retrieved as the cup doesn't even cover the debt. 10 locked peth in cup are burnt from tub

        assertEq(peth.balanceOf(this), 50 ether); // free peth
        assertEq(peth.balanceOf(tub), 40 ether); // locked peth

        tub.bite(cup2);
        tub.free(cup2, tub.ink(cup2)); // 20 peth recovered

        assertEq(peth.balanceOf(this), 70 ether); // free peth
        assertEq(peth.balanceOf(tub), 20 ether); // locked peth

        tub.bite(cup3);
        tub.free(cup3, tub.ink(cup3)); // 20 peth recovered

        assertEq(peth.balanceOf(this), 90 ether); // free peth
        assertEq(peth.balanceOf(tub), 0); // locked peth

        tap.cash(dai.balanceOf(this));

        assertEq(dai.balanceOf(this), 0);
        assertEq(gem.balanceOf(this), 100 ether);

        tap.vent();
        top.flow();
        tub.exit(uint256(peth.balanceOf(this))); // exit 90 peth at price 0/90

        assertEq(gem.balanceOf(tub), 0);
        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(this), 100 ether);
        assertEq(peth.totalSupply(), 0);
    }

    function testPeriodicFixValue() public {
        cageSetup();

        assertEq(gem.balanceOf(tap), 0);
        assertEq(gem.balanceOf(tub), 10 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertEq(peth.balanceOf(this), 0 ether); // free peth
        assertEq(peth.balanceOf(tub), 10 ether); // locked peth

        FakePerson person = new FakePerson(tap);
        dai.transfer(person, 2.5 ether); // Transfer half of DAI balance to the other user

        var price = rdiv(9 ether, 8 ether);
        mark(price);
        top.cage();

        assertEq(gem.balanceOf(tap), rmul(5 ether, top.fix())); // Needed to payout 5 dai
        assertEq(gem.balanceOf(tub), sub(10 ether, rmul(5 ether, top.fix())));

        tap.cash(dai.balanceOf(this));

        assertEq(dai.balanceOf(this),     0 ether);
        assertEq(dai.balanceOf(person), 2.5 ether);
        assertEq(gem.balanceOf(this), add(90 ether, rmul(2.5 ether, top.fix())));

        person.cash();
    }

    function testCageExitAfterPeriod() public {
        var cup = cageSetup();
        mom.setMat(ray(1 ether));  // 100% collat limit
        tub.free(cup, 5 ether);  // 100% collat

        assertEq(uint(top.caged()), 0);
        top.cage();
        assertEq(uint(top.caged()), vox.era());

        // exit fails because ice != 0 && fog !=0 and not enough time passed
        assertTrue(!tub.call(bytes4(keccak256('exit(uint256)')), 5 ether));

        top.setCooldown(1 days);
        warp(1 days);
        assertTrue(!tub.call(bytes4(keccak256('exit(uint256)')), 5 ether));

        warp(1 seconds);
        top.flow();
        assertEq(peth.balanceOf(this), 5 ether);
        assertEq(gem.balanceOf(this), 90 ether);
        assertTrue(tub.call(bytes4(keccak256('exit(uint256)')), 4 ether));
        assertEq(peth.balanceOf(this), 1 ether);
        // n.b. we don't get back 4 as there is still peth in the cup
        assertEq(gem.balanceOf(this), 92 ether);

        // now we can cash in our dai
        assertEq(dai.balanceOf(this), 5 ether);
        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this), 0 ether);
        assertEq(gem.balanceOf(this), 97 ether);

        // the remaining gem can be claimed only if the cup peth is burned
        assertEq(tub.air(), 5 ether);
        assertEq(tap.fog(), 0 ether);
        assertEq(tub.din(), 5 ether);
        assertEq(tap.woe(), 0 ether);
        tub.bite(cup);
        assertEq(tub.air(), 0 ether);
        assertEq(tap.fog(), 5 ether);
        assertEq(tub.din(), 0 ether);
        assertEq(tap.woe(), 5 ether);

        tap.vent();
        assertEq(tap.fog(), 0 ether);

        // now this remaining 1 peth will claim all the remaining 3 ether.
        // this is why exiting early is bad if you want to maximise returns.
        // if we had exited with all the peth earlier, there would be 2.5 gem
        // trapped in the tub.
        tub.exit(1 ether);
        assertEq(peth.balanceOf(this),   0 ether);
        assertEq(gem.balanceOf(this), 100 ether);
    }

    function testShutEmptyCup() public {
        var cup = tub.open();
        var (lad,,,) = tub.cups(cup);
        assertEq(lad, this);
        tub.shut(cup);
        (lad,,,) = tub.cups(cup);
        assertEq(lad, 0);
    }
}

contract LiquidationTest is DaiTestBase {
    function liq(bytes32 cup) internal returns (uint256) {
        // compute the liquidation price of a cup
        var jam = rmul(tub.ink(cup), tub.per());  // this many eth
        var con = rmul(tub.tab(cup), vox.par());  // this much ref debt
        var min = rmul(con, tub.mat());        // minimum ref debt
        return wdiv(min, jam);
    }
    function testLiq() public {
        mom.setCap(100 ether);
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);        // 200% collateralisation

        mom.setMat(ray(1 ether));         // require 100% collateralisation
        assertEq(liq(cup), 1 ether);

        mom.setMat(ray(3 ether / 2));     // require 150% collateralisation
        assertEq(liq(cup), wdiv(3 ether, 2 ether));

        mark(6 ether);
        assertEq(liq(cup), wdiv(3 ether, 2 ether));

        tub.draw(cup, 30 ether);
        assertEq(liq(cup), 6 ether);

        tub.join(10 ether);
        assertEq(liq(cup), 6 ether);

        tub.lock(cup, 10 ether);  // now 40 drawn on 20 gem == 120 ref
        assertEq(liq(cup), 3 ether);
    }
    function collat(bytes32 cup) internal returns (uint256) {
        // compute the collateralised fraction of a cup
        var pro = rmul(tub.ink(cup), tub.tag());
        var con = rmul(tub.tab(cup), vox.par());
        return wdiv(pro, con);
    }
    function testCollat() public {
        mom.setCap(100 ether);
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 10 ether);

        assertEq(collat(cup), 2 ether);  // 200%

        mark(4 ether);
        assertEq(collat(cup), 4 ether);  // 400%

        tub.draw(cup, 15 ether);
        assertEq(collat(cup), wdiv(8 ether, 5 ether));  // 160%

        mark(5 ether);
        tub.free(cup, 5 ether);
        assertEq(collat(cup), 1 ether);  // 100%

        mark(4 ether);
        assertEq(collat(cup), wdiv(4 ether, 5 ether));  // 80%

        tub.wipe(cup, 9 ether);
        assertEq(collat(cup), wdiv(5 ether, 4 ether));  // 125%
    }

    function testBustMint() public {
        mom.setCap(100 ether);
        mom.setMat(ray(wdiv(3 ether, 2 ether)));  // 150% liq limit
        mark(2 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);

        mark(3 ether);
        tub.draw(cup, 16 ether);  // 125% collat
        mark(2 ether);

        assertTrue(!tub.safe(cup));
        tub.bite(cup);
        // 20 ref of gem on 16 ref of dai
        // 125%
        // 100% = 16ref of gem == 8 gem
        assertEq(tap.fog(), 8 ether);

        // 8 peth for sale
        assertEq(tub.per(), ray(1 ether));

        // get 2 peth, pay 4 dai (25% of the debt)
        var dai_before = dai.balanceOf(this);
        var peth_before = peth.balanceOf(this);
        assertEq(dai_before, 16 ether);
        tap.bust(2 ether);
        var dai_after = dai.balanceOf(this);
        var peth_after = peth.balanceOf(this);
        assertEq(dai_before - dai_after, 4 ether);
        assertEq(peth_after - peth_before, 2 ether);

        // price drop. now remaining 6 peth cannot cover bad debt (12 dai)
        mark(1 ether);

        // get 6 peth, pay 6 dai
        tap.bust(6 ether);
        // no more peth remaining to sell
        assertEq(tap.fog(), 0);
        // but peth supply unchanged
        assertEq(peth.totalSupply(), 10 ether);

        // now peth will be minted
        tap.bust(2 ether);
        assertEq(peth.totalSupply(), 12 ether);
    }
    function testBustNoMint() public {
        mom.setCap(1000 ether);
        mom.setMat(ray(2 ether));    // 200% liq limit
        mom.setAxe(ray(1.5 ether));  // 150% liq penalty
        mark(20 ether);

        tub.join(10 ether);
        var cup = tub.open();
        tub.lock(cup, 10 ether);
        tub.draw(cup, 100 ether);  // 200 % collat

        mark(15 ether);
        tub.bite(cup);

        // nothing remains in the cup
        assertEq(tub.tab(cup), 0);
        assertEq(tub.ink(cup), 0);

        // all collateral is now fog
        assertEq(tap.fog(), 10 ether);
        assertEq(tap.woe(), 100 ether);

        // the fog is worth 150 dai and the woe is worth 100 dai.
        // If all the fog is sold, there will be a dai surplus.

        // get some more dai to buy with
        tub.join(10 ether);
        var mug = tub.open();
        tub.lock(mug, 10 ether);
        tub.draw(mug, 50 ether);

        tap.bust(10 ether);
        assertEq(dai.balanceOf(this), 0 ether);
        assertEq(peth.balanceOf(this), 10 ether);
        assertEq(tap.fog(), 0 ether);
        assertEq(tap.woe(), 0 ether);
        assertEq(tap.joy(), 50 ether);

        // joy is available through boom
        assertEq(tap.bid(1 ether), 15 ether);
        tap.boom(2 ether);
        assertEq(dai.balanceOf(this), 30 ether);
        assertEq(peth.balanceOf(this),  8 ether);
        assertEq(tap.fog(), 0 ether);
        assertEq(tap.woe(), 0 ether);
        assertEq(tap.joy(), 20 ether);
    }
}

contract TapTest is DaiTestBase {
    function testTapSetup() public {
        assertEq(dai.balanceOf(tap), tap.joy());
        assertEq(sin.balanceOf(tap), tap.woe());
        assertEq(peth.balanceOf(tap), tap.fog());

        assertEq(tap.joy(), 0);
        assertEq(tap.woe(), 0);
        assertEq(tap.fog(), 0);

        dai.mint(tap, 3);
        sin.mint(tap, 4);
        peth.mint(tap, 5);

        assertEq(tap.joy(), 3);
        assertEq(tap.woe(), 4);
        assertEq(tap.fog(), 5);
    }
    // boom (flap) is surplus sale (dai for peth->burn)
    function testTapBoom() public {
        dai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(dai.balanceOf(this),  0 ether);
        assertEq(peth.balanceOf(this), 60 ether);
        tap.boom(50 ether);
        assertEq(dai.balanceOf(this), 50 ether);
        assertEq(peth.balanceOf(this), 10 ether);
        assertEq(tap.joy(), 0);
    }
    function testFailTapBoomOverJoy() public {
        dai.mint(tap, 50 ether);
        tub.join(60 ether);
        tap.boom(51 ether);
    }
    function testTapBoomHeals() public {
        dai.mint(tap, 60 ether);
        sin.mint(tap, 50 ether);
        tub.join(10 ether);

        tap.boom(0 ether);
        assertEq(tap.joy(), 10 ether);
    }
    function testFailTapBoomNetWoe() public {
        dai.mint(tap, 50 ether);
        sin.mint(tap, 60 ether);
        tub.join(10 ether);
        tap.boom(1 ether);
    }
    function testTapBoomBurnsPeth() public {
        dai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(peth.totalSupply(), 60 ether);
        tap.boom(20 ether);
        assertEq(peth.totalSupply(), 40 ether);
    }
    function testTapBoomIncreasesPer() public {
        dai.mint(tap, 50 ether);
        tub.join(60 ether);

        assertEq(tub.per(), ray(1 ether));
        tap.boom(30 ether);
        assertEq(tub.per(), ray(2 ether));
    }
    function testTapBoomMarkDep() public {
        dai.mint(tap, 50 ether);
        tub.join(50 ether);

        mark(2 ether);
        tap.boom(10 ether);
        assertEq(dai.balanceOf(this), 20 ether);
        assertEq(dai.balanceOf(tap),  30 ether);
        assertEq(peth.balanceOf(this), 40 ether);
    }
    function testTapBoomPerDep() public {
        dai.mint(tap, 50 ether);
        tub.join(50 ether);

        assertEq(tub.per(), ray(1 ether));
        peth.mint(50 ether);  // halves per
        assertEq(tub.per(), ray(.5 ether));

        tap.boom(10 ether);
        assertEq(dai.balanceOf(this),  5 ether);
        assertEq(dai.balanceOf(tap),  45 ether);
        assertEq(peth.balanceOf(this), 90 ether);
    }
    // flip is collateral sale (peth for dai)
    function testTapBustFlip() public {
        dai.mint(50 ether);
        tub.join(50 ether);
        peth.push(tap, 50 ether);
        assertEq(tap.fog(), 50 ether);

        assertEq(peth.balanceOf(this),  0 ether);
        assertEq(dai.balanceOf(this), 50 ether);
        tap.bust(30 ether);
        assertEq(peth.balanceOf(this), 30 ether);
        assertEq(dai.balanceOf(this), 20 ether);
    }
    function testFailTapBustFlipOverFog() public { // FAIL
        dai.mint(50 ether);
        tub.join(50 ether);
        peth.push(tap, 50 ether);

        tap.bust(51 ether);
    }
    function testTapBustFlipHealsNetJoy() public {
        dai.mint(tap, 10 ether);
        sin.mint(tap, 20 ether);
        tub.join(50 ether);
        peth.push(tap, 50 ether);

        dai.mint(15 ether);
        tap.bust(15 ether);
        assertEq(tap.joy(), 5 ether);
        assertEq(tap.woe(), 0 ether);
    }
    function testTapBustFlipHealsNetWoe() public {
        dai.mint(tap, 10 ether);
        sin.mint(tap, 20 ether);
        tub.join(50 ether);
        peth.push(tap, 50 ether);

        dai.mint(5 ether);
        tap.bust(5 ether);
        assertEq(tap.joy(), 0 ether);
        assertEq(tap.woe(), 5 ether);
    }
    // flop is debt sale (woe->peth for dai)
    function testTapBustFlop() public {
        tub.join(50 ether);  // avoid per=1 init case
        dai.mint(100 ether);
        sin.mint(tap, 50 ether);
        assertEq(tap.woe(), 50 ether);

        assertEq(peth.balanceOf(this),  50 ether);
        assertEq(dai.balanceOf(this), 100 ether);
        tap.bust(50 ether);
        assertEq(peth.balanceOf(this), 100 ether);
        assertEq(dai.balanceOf(this),  75 ether);
    }
    function testFailTapBustFlopNetJoy() public {
        tub.join(50 ether);  // avoid per=1 init case
        dai.mint(100 ether);
        sin.mint(tap, 50 ether);
        dai.mint(tap, 100 ether);

        tap.bust(1);  // anything but zero should fail
    }
    function testTapBustFlopMintsPeth() public {
        tub.join(50 ether);  // avoid per=1 init case
        dai.mint(100 ether);
        sin.mint(tap, 50 ether);

        assertEq(peth.totalSupply(),  50 ether);
        tap.bust(20 ether);
        assertEq(peth.totalSupply(),  70 ether);
    }
    function testTapBustFlopDecreasesPer() public {
        tub.join(50 ether);  // avoid per=1 init case
        dai.mint(100 ether);
        sin.mint(tap, 50 ether);

        assertEq(tub.per(), ray(1 ether));
        tap.bust(50 ether);
        assertEq(tub.per(), ray(.5 ether));
    }

    function testTapBustAsk() public {
        tub.join(50 ether);
        assertEq(tap.ask(50 ether), 50 ether);

        peth.mint(50 ether);
        assertEq(tap.ask(50 ether), 25 ether);

        peth.mint(100 ether);
        assertEq(tap.ask(50 ether), 12.5 ether);

        peth.burn(175 ether);
        assertEq(tap.ask(50 ether), 100 ether);

        peth.mint(25 ether);
        assertEq(tap.ask(50 ether), 50 ether);

        peth.mint(10 ether);
        // per = 5 / 6
        assertEq(tap.ask(60 ether), 50 ether);

        peth.mint(30 ether);
        // per = 5 / 9
        assertEq(tap.ask(90 ether), 50 ether);

        peth.mint(10 ether);
        // per = 1 / 2
        assertEq(tap.ask(100 ether), 50 ether);
    }
    // flipflop is debt sale when collateral present
    function testTapBustFlipFlopRounding() public {
        tub.join(50 ether);  // avoid per=1 init case
        dai.mint(100 ether);
        sin.mint(tap, 100 ether);
        peth.push(tap,  50 ether);
        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(),  50 ether);

        assertEq(peth.balanceOf(this),   0 ether);
        assertEq(dai.balanceOf(this), 100 ether);
        assertEq(peth.totalSupply(),    50 ether);

        assertEq(tub.per(), ray(1 ether));
        assertEq(tap.s2s(), ray(1 ether));
        assertEq(tub.tag(), ray(1 ether));
        assertEq(tap.ask(60 ether), 60 ether);
        tap.bust(60 ether);
        assertEq(tub.per(), rdiv(5, 6));
        assertEq(tap.s2s(), rdiv(5, 6));
        assertEq(tub.tag(), rdiv(5, 6));
        // non ray prices would give small rounding error because wad math
        assertEq(tap.ask(60 ether), 50 ether);
        assertEq(peth.totalSupply(),    60 ether);
        assertEq(tap.fog(),             0 ether);
        assertEq(peth.balanceOf(this),  60 ether);
        assertEq(dai.balanceOf(this),  50 ether);
    }
    function testTapBustFlipFlop() public {
        tub.join(50 ether);  // avoid per=1 init case
        dai.mint(100 ether);
        sin.mint(tap, 100 ether);
        peth.push(tap,  50 ether);
        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(),  50 ether);

        assertEq(peth.balanceOf(this),   0 ether);
        assertEq(dai.balanceOf(this), 100 ether);
        assertEq(peth.totalSupply(),    50 ether);
        assertEq(tub.per(), ray(1 ether));
        tap.bust(80 ether);
        assertEq(tub.per(), rdiv(5, 8));
        assertEq(peth.totalSupply(),    80 ether);
        assertEq(tap.fog(),             0 ether);
        assertEq(peth.balanceOf(this),  80 ether);
        assertEq(dai.balanceOf(this),  50 ether);  // expected 50, actual 50 ether + 2???!!!
    }
}

contract TaxTest is DaiTestBase {
    function testEraInit() public {
        assertEq(uint(vox.era()), now);
    }
    function testEraWarp() public {
        warp(20);
        assertEq(uint(vox.era()), now + 20);
    }
    function taxSetup() public returns (bytes32 cup) {
        mark(10 ether);
        gem.deposit.value(1000 ether)();

        mom.setCap(1000 ether);
        mom.setTax(1000000564701133626865910626);  // 5% / day
        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    function testTaxEra() public {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 110.25 ether);
    }
    // rum doesn't change on drip
    function testTaxRum() public {
        taxSetup();
        assertEq(tub.rum(),    100 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.rum(),    100 ether);
    }
    // din increases on drip
    function testTaxDin() public {
        taxSetup();
        assertEq(tub.din(),    100 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.din(),    105 ether);
    }
    // Tax accumulates as dai surplus, and CDP debt
    function testTaxJoy() public {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      0 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),      5 ether);
    }
    function testTaxJoy2() public {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      0 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),      5 ether);
        // now ensure din != rum
        tub.wipe(cup, 5 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      5 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),     10 ether);
    }
    function testTaxJoy3() public {
        var cup = taxSetup();
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      0 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),      5 ether);
        // now ensure rum changes
        tub.wipe(cup, 5 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      5 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),     10 ether);
        // and ensure the last rum != din either
        tub.wipe(cup, 5 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),     10 ether);
        warp(1 days);
        tub.drip();
        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),     15 ether);
    }
    function testTaxDraw() public {
        var cup = taxSetup();
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.draw(cup, 100 ether);
        assertEq(tub.tab(cup), 205 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 215.25 ether);
    }
    function testTaxWipe() public {
        var cup = taxSetup();
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.wipe(cup, 50 ether);
        assertEq(tub.tab(cup), 55 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 57.75 ether);
    }
    // collected fees are available through boom
    function testTaxBoom() public {
        taxSetup();
        warp(1 days);
        // should have 5 dai available == 0.5 peth
        tub.join(0.5 ether);  // get some unlocked peth

        assertEq(peth.totalSupply(),   100.5 ether);
        assertEq(dai.balanceOf(tap),    0 ether);
        assertEq(sin.balanceOf(tap),    0 ether);
        assertEq(dai.balanceOf(this), 100 ether);
        tub.drip();
        assertEq(dai.balanceOf(tap),    5 ether);
        tap.boom(0.5 ether);
        assertEq(peth.totalSupply(),   100 ether);
        assertEq(dai.balanceOf(tap),    0 ether);
        assertEq(sin.balanceOf(tap),    0 ether);
        assertEq(dai.balanceOf(this), 105 ether);
    }
    // Tax can flip a cup to unsafe
    function testTaxSafe() public {
        var cup = taxSetup();
        mark(1 ether);
        assertTrue(tub.safe(cup));
        warp(1 days);
        assertTrue(!tub.safe(cup));
    }
    function testTaxBite() public {
        var cup = taxSetup();
        mark(1 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.bite(cup);
        assertEq(tub.tab(cup),   0 ether);
        assertEq(tap.woe(),    105 ether);
    }
    function testTaxBiteRounding() public {
        var cup = taxSetup();
        mark(1 ether);
        mom.setMat(ray(1.5 ether));
        mom.setAxe(ray(1.4 ether));
        mom.setTax(ray(1.000000001547126 ether));
        // log_named_uint('tab', tub.tab(cup));
        // log_named_uint('sin', tub.din());
        for (uint i=0; i<=50; i++) {
            warp(10);
            // log_named_uint('tab', tub.tab(cup));
            // log_named_uint('sin', tub.din());
        }
        uint256 debtAfterWarp = rmul(100 ether, rpow(tub.tax(), 510));
        assertEq(tub.tab(cup), debtAfterWarp);
        tub.bite(cup);
        assertEq(tub.tab(cup), 0 ether);
        assertEq(tap.woe(), rmul(100 ether, rpow(tub.tax(), 510)));
    }
    function testTaxBail() public {
        var cup = taxSetup();
        warp(1 days);
        tub.drip();
        mark(10 ether);
        top.cage();

        warp(1 days);  // should have no effect
        tub.drip();

        assertEq(peth.balanceOf(this),  0 ether);
        assertEq(peth.balanceOf(tub), 100 ether);
        tub.bite(cup);
        tub.free(cup, tub.ink(cup));
        assertEq(peth.balanceOf(this), 89.5 ether);
        assertEq(peth.balanceOf(tub),     0 ether);

        assertEq(dai.balanceOf(this),  100 ether);
        assertEq(gem.balanceOf(this), 1000 ether);
        tap.cash(dai.balanceOf(this));
        assertEq(dai.balanceOf(this),    0 ether);
        assertEq(gem.balanceOf(this), 1010 ether);
    }
    function testTaxCage() public {
        // after cage, un-distributed tax revenue remains as joy - dai
        // surplus in the tap. The remaining joy, plus all outstanding
        // dai, balances the sin debt in the tub, plus any debt (woe) in
        // the tap.

        // The effect of this is that joy remaining in tap is
        // effectively distributed to all peth holders.
        var cup = taxSetup();
        warp(1 days);
        mark(10 ether);

        assertEq(tap.joy(), 0 ether);
        top.cage();                // should drip up to date
        assertEq(tap.joy(), 5 ether);
        warp(1 days);  tub.drip();  // should have no effect
        assertEq(tap.joy(), 5 ether);

        var owe = tub.tab(cup);
        assertEq(owe, 105 ether);
        assertEq(tub.din(), owe);
        assertEq(tap.woe(), 0);
        tub.bite(cup);
        assertEq(tub.din(), 0);
        assertEq(tap.woe(), owe);
        assertEq(tap.joy(), 5 ether);
    }
}

contract WayTest is DaiTestBase {
    function waySetup() public returns (bytes32 cup) {
        mark(10 ether);
        gem.deposit.value(1000 ether)();

        mom.setCap(1000 ether);

        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    // what does way actually do?
    // it changes the value of dai relative to ref
    // way > 1 -> par increasing, more ref per dai
    // way < 1 -> par decreasing, less ref per dai

    // this changes the safety level of cups,
    // affecting `draw`, `wipe`, `free` and `bite`

    // if way < 1, par is decreasing and the con (in ref)
    // of a cup is decreasing, so cup holders need
    // less ref to wipe (but the same dai)
    // This makes cups *more* collateralised with time.
    function testTau() public {
        assertEq(uint(vox.era()), now);
        assertEq(uint(vox.tau()), now);
    }
    function testWayPar() public {
        mom.setWay(999999406327787478619865402);  // -5% / day

        assertEq(wad(vox.par()), 1.00 ether);
        warp(1 days);
        assertEq(wad(vox.par()), 0.95 ether);

        mom.setWay(1000000021979553151239153027);  // 200% / year
        warp(1 years);
        assertEq(wad(vox.par()), 1.90 ether);
    }
    function testWayDecreasingPrincipal() public {
        var cup = waySetup();
        mark(0.98 ether);
        assertTrue(!tub.safe(cup));

        mom.setWay(999999406327787478619865402);  // -5% / day
        warp(1 days);
        assertTrue(tub.safe(cup));
    }
    // `cage` is slightly affected: the cage price is
    // now in *dai per gem*, where before ref per gem
    // was equivalent.
    // `bail` is unaffected, as all values are in dai.
    function testWayCage() public {
        waySetup();

        mom.setWay(1000000021979553151239153027);  // 200% / year
        warp(1 years);  // par now 2

        // we have 100 dai
        // gem is worth 10 ref
        // dai is worth 2 ref
        // we should get back 100 / (10 / 2) = 20 gem

        top.cage();

        assertEq(gem.balanceOf(this), 1000 ether);
        assertEq(dai.balanceOf(this),  100 ether);
        assertEq(dai.balanceOf(tap),     0 ether);
        tap.cash(dai.balanceOf(this));
        assertEq(gem.balanceOf(this), 1020 ether);
        assertEq(dai.balanceOf(this),    0 ether);
        assertEq(dai.balanceOf(tap),     0 ether);
    }

    // `boom` and `bust` as par is now needed to determine
    // the peth / dai price.
    function testWayBust() public {
        var cup = waySetup();
        mark(0.5 ether);
        tub.bite(cup);

        assertEq(tap.joy(),   0 ether);
        assertEq(tap.woe(), 100 ether);
        assertEq(tap.fog(), 100 ether);
        assertEq(dai.balanceOf(this), 100 ether);

        tap.bust(50 ether);

        assertEq(tap.fog(),  50 ether);
        assertEq(tap.woe(),  75 ether);
        assertEq(dai.balanceOf(this), 75 ether);

        mom.setWay(999999978020447331861593082);  // -50% / year
        warp(1 years);
        assertEq(wad(vox.par()), 0.5 ether);
        // dai now worth half as much, so we cover twice as much debt
        // for the same peth
        tap.bust(50 ether);

        assertEq(tap.fog(),   0 ether);
        assertEq(tap.woe(),  25 ether);
        assertEq(dai.balanceOf(this), 25 ether);
    }
}

contract GapTest is DaiTestBase {
    // boom and bust have a spread parameter
    function setUp() public {
        super.setUp();

        gem.deposit.value(500 ether)();
        tub.join(500 ether);

        dai.mint(500 ether);
        sin.mint(500 ether);

        mark(2 ether);  // 2 ref per eth => 2 dai per peth
    }
    function testGapDaiTapBid() public {
        mark(1 ether);
        mom.setTapGap(1.01 ether);  // 1% spread
        assertEq(tap.bid(1 ether), 0.99 ether);
        mark(2 ether);
        assertEq(tap.bid(1 ether), 1.98 ether);
    }
    function testGapDaiTapAsk() public {
        mark(1 ether);
        mom.setTapGap(1.01 ether);  // 1% spread
        assertEq(tap.ask(1 ether), 1.01 ether);
        mark(2 ether);
        assertEq(tap.ask(1 ether), 2.02 ether);
    }
    function testGapBoom() public {
        dai.push(tap, 198 ether);
        assertEq(tap.joy(), 198 ether);

        mom.setTapGap(1.01 ether);  // 1% spread

        var dai_before = dai.balanceOf(this);
        var peth_before = peth.balanceOf(this);
        tap.boom(50 ether);
        var dai_after = dai.balanceOf(this);
        var peth_after = peth.balanceOf(this);
        assertEq(dai_after - dai_before, 99 ether);
        assertEq(peth_before - peth_after, 50 ether);
    }
    function testGapBust() public {
        peth.push(tap, 100 ether);
        sin.push(tap, 200 ether);
        assertEq(tap.fog(), 100 ether);
        assertEq(tap.woe(), 200 ether);

        mom.setTapGap(1.01 ether);

        var dai_before = dai.balanceOf(this);
        var peth_before = peth.balanceOf(this);
        tap.bust(50 ether);
        var dai_after = dai.balanceOf(this);
        var peth_after = peth.balanceOf(this);
        assertEq(peth_after - peth_before,  50 ether);
        assertEq(dai_before - dai_after, 101 ether);
    }
    function testGapLimits() public {
        uint256 legal   = 1.04 ether;
        uint256 illegal = 1.06 ether;

        var setGap = bytes4(keccak256("setTapGap(uint256)"));

        assertTrue(mom.call(setGap, legal));
        assertEq(tap.gap(), legal);

        assertTrue(!mom.call(setGap, illegal));
        assertEq(tap.gap(), legal);
    }

    // join and exit have a spread parameter
    function testGapJarBidAsk() public {
        assertEq(tub.per(), ray(1 ether));
        assertEq(tub.bid(1 ether), 1 ether);
        assertEq(tub.ask(1 ether), 1 ether);

        mom.setTubGap(1.01 ether);
        assertEq(tub.bid(1 ether), 0.99 ether);
        assertEq(tub.ask(1 ether), 1.01 ether);

        assertEq(peth.balanceOf(this), 500 ether);
        assertEq(peth.totalSupply(),   500 ether);
        peth.burn(250 ether);

        assertEq(tub.per(), ray(2 ether));
        assertEq(tub.bid(1 ether), 1.98 ether);
        assertEq(tub.ask(1 ether), 2.02 ether);
    }
    function testGapJoin() public {
        gem.deposit.value(100 ether)();

        mom.setTubGap(1.05 ether);
        var peth_before = peth.balanceOf(this);
        var gem_before = gem.balanceOf(this);
        tub.join(100 ether);
        var peth_after = peth.balanceOf(this);
        var gem_after = gem.balanceOf(this);

        assertEq(peth_after - peth_before, 100 ether);
        assertEq(gem_before - gem_after, 105 ether);
    }
    function testGapExit() public {
        gem.deposit.value(100 ether)();
        tub.join(100 ether);

        mom.setTubGap(1.05 ether);
        var peth_before = peth.balanceOf(this);
        var gem_before = gem.balanceOf(this);
        tub.exit(100 ether);
        var peth_after = peth.balanceOf(this);
        var gem_after = gem.balanceOf(this);

        assertEq(gem_after - gem_before,  95 ether);
        assertEq(peth_before - peth_after, 100 ether);
    }
}

contract GasTest is DaiTestBase {
    bytes32 cup;
    function setUp() public {
        super.setUp();

        mark(1 ether);
        gem.deposit.value(1000 ether)();

        mom.setCap(1000 ether);
        mom.setAxe(ray(1 ether));
        mom.setMat(ray(1 ether));
        mom.setTax(ray(1 ether));
        mom.setFee(ray(1 ether));
        mom.setTubGap(1 ether);
        mom.setTapGap(1 ether);

        cup = tub.open();
        tub.join(1000 ether);
        tub.lock(cup, 500 ether);
        tub.draw(cup, 100 ether);
    }
    function doLock(uint256 wad) public logs_gas {
        tub.lock(cup, wad);
    }
    function doFree(uint256 wad) public logs_gas {
        tub.free(cup, wad);
    }
    function doDraw(uint256 wad) public logs_gas {
        tub.draw(cup, wad);
    }
    function doWipe(uint256 wad) public logs_gas {
        tub.wipe(cup, wad);
    }
    function doDrip() public logs_gas {
        tub.drip();
    }
    function doBoom(uint256 wad) public logs_gas {
        tap.boom(wad);
    }

    uint256 tic = 15 seconds;

    function testGasLock() public {
        warp(tic);
        doLock(100 ether);
        // assertTrue(false);
    }
    function testGasFree() public {
        warp(tic);
        doFree(100 ether);
        // assertTrue(false);
    }
    function testGasDraw() public {
        warp(tic);
        doDraw(100 ether);
        // assertTrue(false);
    }
    function testGasWipe() public {
        warp(tic);
        doWipe(100 ether);
        // assertTrue(false);
    }
    function testGasBoom() public {
        warp(tic);
        tub.join(10 ether);
        dai.mint(100 ether);
        dai.push(tap, 100 ether);
        peth.approve(tap, uint(-1));
        doBoom(1 ether);
        // assertTrue(false);
    }
    function testGasBoomHeal() public {
        warp(tic);
        tub.join(10 ether);
        dai.mint(100 ether);
        sin.mint(100 ether);
        dai.push(tap, 100 ether);
        sin.push(tap,  50 ether);
        peth.approve(tap, uint(-1));
        doBoom(1 ether);
        // assertTrue(false);
    }
    function testGasDripNoop() public {
        tub.drip();
        doDrip();
    }
    function testGasDrip1s() public {
        warp(1 seconds);
        doDrip();
    }
    function testGasDrip1m() public {
        warp(1 minutes);
        doDrip();
    }
    function testGasDrip1h() public {
        warp(1 hours);
        doDrip();
    }
    function testGasDrip1d() public {
        warp(1 days);
        doDrip();
    }
}

contract FeeTest is DaiTestBase {
    function feeSetup() public returns (bytes32 cup) {
        mark(10 ether);
        mark(gov, 1 ether / 2);
        gem.deposit.value(1000 ether)();
        gov.mint(100 ether);

        mom.setCap(1000 ether);
        mom.setFee(1000000564701133626865910626);  // 5% / day

        // warp(1 days);  // make chi,rhi != 1

        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    function testFeeSet() public {
        assertEq(tub.fee(), ray(1 ether));
        mom.setFee(ray(1.000000001 ether));
        assertEq(tub.fee(), ray(1.000000001 ether));
    }
    function testFeeSetup() public {
        feeSetup();
        assertEq(tub.chi(), ray(1 ether));
        assertEq(tub.rhi(), ray(1 ether));
    }
    function testFeeDrip() public {
        feeSetup();
        warp(1 days);
        assertEq(tub.chi() / 10 ** 9, 1.00 ether);
        assertEq(tub.rhi() / 10 ** 9, 1.05 ether);
    }
    // Unpaid fees do not accumulate as sin
    function testFeeIce() public {
        var cup = feeSetup();
        assertEq(tub.din(),    100 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   0 ether);
        warp(1 days);
        assertEq(tub.din(),    100 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   5 ether);
    }
    function testFeeDraw() public {
        var cup = feeSetup();
        warp(1 days);
        assertEq(tub.rap(cup),   5 ether);
        tub.draw(cup, 100 ether);
        assertEq(tub.rap(cup),   5 ether);
        warp(1 days);
        assertEq(tub.rap(cup),  15.25 ether);
    }
    function testFeeWipe() public {
        var cup = feeSetup();
        warp(1 days);
        assertEq(tub.rap(cup),   5 ether);
        tub.wipe(cup, 50 ether);
        assertEq(tub.rap(cup),  2.5 ether);
        warp(1 days);
        assertEq(tub.rap(cup),  5.125 ether);
    }
    function testFeeCalcFromRap() public {
        var cup = feeSetup();

        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   0 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   5 ether);
    }
    function testFeeWipePays() public {
        var cup = feeSetup();
        warp(1 days);

        assertEq(tub.rap(cup),          5 ether);
        assertEq(gov.balanceOf(this), 100 ether);
        tub.wipe(cup, 50 ether);
        assertEq(tub.tab(cup),         50 ether);
        assertEq(gov.balanceOf(this),  95 ether);
    }
    function testFeeWipeMoves() public {
        var cup = feeSetup();
        warp(1 days);

        assertEq(gov.balanceOf(this), 100 ether);
        assertEq(gov.balanceOf(pit),    0 ether);
        tub.wipe(cup, 50 ether);
        assertEq(gov.balanceOf(this),  95 ether);
        assertEq(gov.balanceOf(pit),    5 ether);
    }
    function testFeeWipeAll() public {
        var cup = feeSetup();
        warp(1 days);

        var wad = tub.tab(cup);
        assertEq(wad, 100 ether);
        var owe = tub.rap(cup);
        assertEq(owe, 5 ether);

        var ( , , art, ire) = tub.cups(cup);
        assertEq(art, 100 ether);
        assertEq(ire, 100 ether);
        assertEq(rdiv(wad, tub.chi()), art);
        assertEq(rdiv(add(wad, owe), tub.rhi()), ire);

        assertEq(tub.rap(cup),   5 ether);
        assertEq(tub.tab(cup), 100 ether);
        assertEq(gov.balanceOf(this), 100 ether);
        tub.wipe(cup, 100 ether);
        assertEq(tub.rap(cup), 0 ether);
        assertEq(tub.tab(cup), 0 ether);
        assertEq(gov.balanceOf(this), 90 ether);
    }
    function testFeeWipeNoFeed() public {
        var cup = feeSetup();
        pep.void();
        warp(1 days);

        // fees continue to accumulate
        assertEq(tub.rap(cup),   5 ether);

        // gov is no longer taken
        assertEq(gov.balanceOf(this), 100 ether);
        tub.wipe(cup, 50 ether);
        assertEq(gov.balanceOf(this), 100 ether);

        // fees are still wiped proportionally
        assertEq(tub.rap(cup),  2.5 ether);
        warp(1 days);
        assertEq(tub.rap(cup),  5.125 ether);
    }
    function testFeeWipeShut() public {
        var cup = feeSetup();
        warp(1 days);
        tub.shut(cup);
    }
    function testFeeWipeShutEmpty() public {
        feeSetup();
        var cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        warp(1 days);
        tub.shut(cup);
    }
}

contract PitTest is DaiTestBase {
    function testPitBurns() public {
        gov.mint(1 ether);
        assertEq(gov.balanceOf(pit), 0 ether);
        gov.push(pit, 1 ether);

        // mock gov authority
        var guard = new DSGuard();
        guard.permit(pit, gov, bytes4(keccak256('burn(uint256)')));
        gov.setAuthority(guard);

        assertEq(gov.balanceOf(pit), 1 ether);
        pit.burn(gov);
        assertEq(gov.balanceOf(pit), 0 ether);
    }
}

contract FeeTaxTest is DaiTestBase {
    function feeSetup() public returns (bytes32 cup) {
        mark(10 ether);
        mark(gov, 1 ether / 2);
        gem.deposit.value(1000 ether)();
        gov.mint(100 ether);

        mom.setCap(1000 ether);
        mom.setFee(1000000564701133626865910626);  // 5% / day
        mom.setTax(1000000564701133626865910626);  // 5% / day

        // warp(1 days);  // make chi,rhi != 1

        cup = tub.open();
        tub.join(100 ether);
        tub.lock(cup, 100 ether);
        tub.draw(cup, 100 ether);
    }
    function testFeeTaxDrip() public {
        feeSetup();
        warp(1 days);
        assertEq(tub.chi() / 10 ** 9, 1.0500 ether);
        assertEq(tub.rhi() / 10 ** 9, 1.1025 ether);
    }
    // Unpaid fees do not accumulate as sin
    function testFeeTaxIce() public {
        var cup = feeSetup();

        assertEq(tub.tab(cup), 100 ether);
        assertEq(tub.rap(cup),   0 ether);

        assertEq(tub.din(),    100 ether);
        assertEq(tap.joy(),      0 ether);

        warp(1 days);

        assertEq(tub.tab(cup), 105 ether);
        assertEq(tub.rap(cup),   5.25 ether);

        assertEq(tub.din(),    105 ether);
        assertEq(tap.joy(),      5 ether);
    }
    function testFeeTaxDraw() public {
        var cup = feeSetup();
        warp(1 days);
        assertEq(tub.tab(cup), 105 ether);
        tub.draw(cup, 100 ether);
        assertEq(tub.tab(cup), 205 ether);
    }
    function testFeeTaxCalcFromRap() public {
        var cup = feeSetup();

        assertEq(tub.tab(cup), 100.00 ether);
        assertEq(tub.rap(cup),   0.00 ether);
        warp(1 days);
        assertEq(tub.tab(cup), 105.00 ether);
        assertEq(tub.rap(cup),   5.25 ether);
    }
    function testFeeTaxWipeAll() public {
        var cup = feeSetup();
        warp(1 days);

        var wad = tub.tab(cup);
        assertEq(wad, 105 ether);
        var owe = tub.rap(cup);
        assertEq(owe, 5.25 ether);

        var ( , , art, ire) = tub.cups(cup);
        assertEq(art, 100 ether);
        assertEq(ire, 100 ether);
        assertEq(rdiv(wad, tub.chi()), art);
        assertEq(rdiv(add(wad, owe), tub.rhi()), ire);

        dai.mint(5 ether);  // need to magic up some extra dai to pay tax

        assertEq(tub.rap(cup), 5.25 ether);
        assertEq(gov.balanceOf(this), 100 ether);
        tub.wipe(cup, 105 ether);
        assertEq(tub.rap(cup), 0 ether);
        assertEq(gov.balanceOf(this), 89.5 ether);
    }
}

contract AxeTest is DaiTestBase {
    function axeSetup() public returns (bytes32) {
        mom.setCap(1000 ether);
        mark(1 ether);
        mom.setMat(ray(2 ether));       // require 200% collat
        tub.join(20 ether);
        var cup = tub.open();
        tub.lock(cup, 20 ether);
        tub.draw(cup, 10 ether);       // 200% collateralisation

        return cup;
    }
    function testAxeBite1() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));
        mom.setMat(ray(2.1 ether));

        assertEq(tub.ink(cup), 20 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 5 ether);
    }
    function testAxeBite2() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));
        mark(0.8 ether);    // collateral value 20 -> 16

        assertEq(tub.ink(cup), 20 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 1.25 ether);  // (1 / 0.8)
    }
    function testAxeBiteParity() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));
        mark(0.5 ether);    // collateral value 20 -> 10

        assertEq(tub.ink(cup), 20 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 0 ether);
    }
    function testAxeBiteUnder() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));
        mark(0.4 ether);    // collateral value 20 -> 8

        assertEq(tub.ink(cup), 20 ether);
        tub.bite(cup);
        assertEq(tub.ink(cup), 0 ether);
    }
    function testZeroAxeCage() public {
        var cup = axeSetup();

        mom.setAxe(ray(1 ether));

        assertEq(tub.ink(cup), 20 ether);
        top.cage();
        tub.bite(cup);
        tap.vent();
        top.flow();
        assertEq(tub.ink(cup), 10 ether);
    }
    function testAxeCage() public {
        var cup = axeSetup();

        mom.setAxe(ray(1.5 ether));

        assertEq(tub.ink(cup), 20 ether);
        top.cage();
        tub.bite(cup);
        tap.vent();
        top.flow();
        assertEq(tub.ink(cup), 10 ether);
    }
}

contract DustTest is DaiTestBase {
    function testFailLockUnderDust() public {
        tub.join(1 ether);
        var cup = tub.open();
        tub.lock(cup, 0.0049 ether);
    }
    function testFailFreeUnderDust() public {
        tub.join(1 ether);
        var cup = tub.open();
        tub.lock(cup, 1 ether);
        tub.free(cup, 0.995 ether);
    }
}
