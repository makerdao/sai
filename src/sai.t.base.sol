pragma solidity ^0.5.11;

import "ds-test/test.sol";
import "ds-math/math.sol";

import './fab.sol';
import './weth9.sol';
import './mom.sol';
import './pit.sol';

contract TestWarp is DSNote {
    uint256  _era;

    constructor() public {
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

contract DevTub is SaiTub, TestWarp {
    constructor(
        DSToken  sai_,
        DSToken  sin_,
        DSToken  skr_,
        ERC20    gem_,
        DSToken  gov_,
        DSValue  pip_,
        DSValue  pep_,
        SaiVox   vox_,
        address  pit_
    ) public
      SaiTub(sai_, sin_, skr_, gem_, gov_, pip_, pep_, vox_, pit_) {}
}

contract DevTop is SaiTop, TestWarp {
    constructor(SaiTub tub_, SaiTap tap_) public SaiTop(tub_, tap_) {}
}

contract DevVox is SaiVox, TestWarp {
    constructor(uint par_) SaiVox(par_) public {}
}

contract DevVoxFab {
    function newVox() public returns (DevVox vox) {
        vox = new DevVox(10 ** 27);
        vox.setOwner(msg.sender);
    }
}

contract DevTubFab {
    function newTub(DSToken sai, DSToken sin, DSToken skr, DSToken gem, DSToken gov, DSValue pip, DSValue pep, SaiVox vox, address pit) public returns (DevTub tub) {
        tub = new DevTub(sai, sin, skr, gem, gov, pip, pep, vox, pit);
        tub.setOwner(msg.sender);
    }
}

contract DevTopFab {
    function newTop(DevTub tub, SaiTap tap) public returns (DevTop top) {
        top = new DevTop(tub, tap);
        top.setOwner(msg.sender);
    }
}

contract DevDadFab {
    function newDad() public returns (DSGuard dad) {
        dad = new DSGuard();
        // convenience in tests
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).sai()), bytes32(bytes4(keccak256('mint(uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).sai()), bytes32(bytes4(keccak256('burn(uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).sai()), bytes32(bytes4(keccak256('mint(address,uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).sai()), bytes32(bytes4(keccak256('burn(address,uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).sin()), bytes32(bytes4(keccak256('mint(uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).sin()), bytes32(bytes4(keccak256('burn(uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).sin()), bytes32(bytes4(keccak256('mint(address,uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).sin()), bytes32(bytes4(keccak256('burn(address,uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).skr()), bytes32(bytes4(keccak256('mint(uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).skr()), bytes32(bytes4(keccak256('burn(uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).skr()), bytes32(bytes4(keccak256('mint(address,uint256)'))));
        dad.permit(DaiFab(msg.sender).owner(), address(DaiFab(msg.sender).skr()), bytes32(bytes4(keccak256('burn(address,uint256)'))));
        dad.setOwner(msg.sender);
    }
}

contract SaiTestBase is DSTest, DSMath {
    DevVox   vox;
    DevTub   tub;
    DevTop   top;
    SaiTap   tap;

    SaiMom   mom;

    WETH9    gem;
    DSToken  sai;
    DSToken  sin;
    DSToken  skr;
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
    function try_call(address target, bytes4 sig, uint val) internal returns (bool) {
        (bool ok,) = address(target).call(abi.encodeWithSelector(sig, val));
        return ok;
    }
    function try_call(address target, bytes4 sig, address addr) internal returns (bool) {
        (bool ok,) = address(target).call(abi.encodeWithSelector(sig, addr));
        return ok;
    }

    function setUp() public {
        GemFab gemFab = new GemFab();
        DevVoxFab voxFab = new DevVoxFab();
        DevTubFab tubFab = new DevTubFab();
        TapFab tapFab = new TapFab();
        DevTopFab topFab = new DevTopFab();
        MomFab momFab = new MomFab();
        DevDadFab dadFab = new DevDadFab();

        DaiFab daiFab = new DaiFab(gemFab, VoxFab(address(voxFab)), TubFab(address(tubFab)), tapFab, TopFab(address(topFab)), momFab, DadFab(address(dadFab)));

        gem = new WETH9();
        gem.deposit.value(100 ether)();
        gov = new DSToken('GOV');
        pip = new DSValue();
        pep = new DSValue();
        pit = new GemPit();

        daiFab.makeTokens();
        daiFab.makeVoxTub(ERC20(address(gem)), gov, pip, pep, address(pit));
        daiFab.makeTapTop();
        daiFab.configParams();
        daiFab.verifyParams();
        DSRoles authority = new DSRoles();
        authority.setRootUser(address(this), true);
        daiFab.configAuth(authority);

        sai = DSToken(daiFab.sai());
        sin = DSToken(daiFab.sin());
        skr = DSToken(daiFab.skr());
        vox = DevVox(address(daiFab.vox()));
        tub = DevTub(address(daiFab.tub()));
        tap = SaiTap(daiFab.tap());
        top = DevTop(address(daiFab.top()));
        mom = SaiMom(daiFab.mom());
        dad = DSRoles(address(daiFab.dad()));

        sai.approve(address(tub));
        skr.approve(address(tub));
        gem.approve(address(tub), uint(-1));
        gov.approve(address(tub));

        sai.approve(address(tap));
        skr.approve(address(tap));

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
