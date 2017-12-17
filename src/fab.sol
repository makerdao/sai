pragma solidity ^0.4.18;

import "ds-auth/auth.sol";
import 'ds-token/token.sol';
import 'ds-guard/guard.sol';
import 'ds-roles/roles.sol';
import 'ds-value/value.sol';

import './mom.sol';

contract GemFab {
    function newTok(bytes32 name) public returns (DSToken token) {
        token = new DSToken(name);
        token.setOwner(msg.sender);
    }
}

contract VoxFab {
    function newVox() public returns (DaiVox vox) {
        vox = new DaiVox(10 ** 27);
        vox.setOwner(msg.sender);
    }
}

contract TubFab {
    function newTub(DSToken dai, DSToken sin, DSToken peth, ERC20 gem, DSToken gov, DSValue pip, DSValue pep, DaiVox vox, address pit) public returns (DaiTub tub) {
        tub = new DaiTub(dai, sin, peth, gem, gov, pip, pep, vox, pit);
        tub.setOwner(msg.sender);
    }
}

contract TapFab {
    function newTap(DaiTub tub) public returns (DaiTap tap) {
        tap = new DaiTap(tub);
        tap.setOwner(msg.sender);
    }
}

contract TopFab {
    function newTop(DaiTub tub, DaiTap tap) public returns (DaiTop top) {
        top = new DaiTop(tub, tap);
        top.setOwner(msg.sender);
    }
}

contract MomFab {
    function newMom(DaiTub tub, DaiTap tap, DaiVox vox) public returns (DaiMom mom) {
        mom = new DaiMom(tub, tap, vox);
        mom.setOwner(msg.sender);
    }
}

contract DadFab {
    function newDad() public returns (DSGuard dad) {
        dad = new DSGuard();
        dad.setOwner(msg.sender);
    }
}

contract DaiFab is DSAuth {
    GemFab public gemFab;
    VoxFab public voxFab;
    TapFab public tapFab;
    TubFab public tubFab;
    TopFab public topFab;
    MomFab public momFab;
    DadFab public dadFab;

    DSToken public dai;
    DSToken public sin;
    DSToken public peth;

    DaiVox public vox;
    DaiTub public tub;
    DaiTap public tap;
    DaiTop public top;

    DaiMom public mom;
    DSGuard public dad;

    uint8 public step = 0;

    function DaiFab(GemFab gemFab_, VoxFab voxFab_, TubFab tubFab_, TapFab tapFab_, TopFab topFab_, MomFab momFab_, DadFab dadFab_) public {
        gemFab = gemFab_;
        voxFab = voxFab_;
        tubFab = tubFab_;
        tapFab = tapFab_;
        topFab = topFab_;
        momFab = momFab_;
        dadFab = dadFab_;
    }

    function makeTokens() public auth {
        require(step == 0);
        dai = gemFab.newTok('DAI');
        sin = gemFab.newTok('SIN');
        peth = gemFab.newTok('PETH');
        step += 1;
    }

    function makeVoxTub(ERC20 gem, DSToken gov, DSValue pip, DSValue pep, address pit) public auth {
        require(step == 1);
        require(address(gem) != 0x0);
        require(address(gov) != 0x0);
        require(address(pip) != 0x0);
        require(address(pep) != 0x0);
        require(pit != 0x0);
        vox = voxFab.newVox();
        tub = tubFab.newTub(dai, sin, peth, gem, gov, pip, pep, vox, pit);
        step += 1;
    }

    function makeTapTop() public auth {
        require(step == 2);
        tap = tapFab.newTap(tub);
        tub.turn(tap);
        top = topFab.newTop(tub, tap);
        step += 1;
    }

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(s));
    }

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 9;
    }

    // Liquidation Ratio   150%
    // Liquidation Penalty 13%
    // Stability Fee       0.05%
    // PETH Fee            0%
    // Boom/Bust Spread   -3%
    // Join/Exit Spread    0%
    // Debt Ceiling        0
    function configParams() public auth {
        require(step == 3);

        tub.mold("cap", 0);
        tub.mold("mat", ray(1.5  ether));
        tub.mold("axe", ray(1.13 ether));
        tub.mold("fee", 1000000000158153903837946257);  // 0.5% / year
        tub.mold("tax", ray(1 ether));
        tub.mold("gap", 1 ether);

        tap.mold("gap", 0.97 ether);

        step += 1;
    }

    function verifyParams() public auth {
        require(step == 4);

        require(tub.cap() == 0);
        require(tub.mat() == 1500000000000000000000000000);
        require(tub.axe() == 1130000000000000000000000000);
        require(tub.fee() == 1000000000158153903837946257);
        require(tub.tax() == 1000000000000000000000000000);
        require(tub.gap() == 1000000000000000000);

        require(tap.gap() == 970000000000000000);

        require(vox.par() == 1000000000000000000000000000);
        require(vox.how() == 0);

        step += 1;
    }

    function configAuth(DSAuthority authority) public auth {
        require(step == 5);
        require(address(authority) != 0x0);

        mom = momFab.newMom(tub, tap, vox);
        dad = dadFab.newDad();

        vox.setAuthority(dad);
        vox.setOwner(0);
        tub.setAuthority(dad);
        tub.setOwner(0);
        tap.setAuthority(dad);
        tap.setOwner(0);
        dai.setAuthority(dad);
        dai.setOwner(0);
        sin.setAuthority(dad);
        sin.setOwner(0);
        peth.setAuthority(dad);
        peth.setOwner(0);

        top.setAuthority(authority);
        top.setOwner(0);
        mom.setAuthority(authority);
        mom.setOwner(0);

        dad.permit(top, tub, S("cage(uint256,uint256)"));
        dad.permit(top, tub, S("flow()"));
        dad.permit(top, tap, S("cage(uint256)"));

        dad.permit(tub, peth, S('mint(address,uint256)'));
        dad.permit(tub, peth, S('burn(address,uint256)'));

        dad.permit(tub, dai, S('mint(address,uint256)'));
        dad.permit(tub, dai, S('burn(address,uint256)'));

        dad.permit(tub, sin, S('mint(address,uint256)'));

        dad.permit(tap, dai, S('mint(address,uint256)'));
        dad.permit(tap, dai, S('burn(address,uint256)'));
        dad.permit(tap, dai, S('burn(uint256)'));
        dad.permit(tap, sin, S('burn(uint256)'));

        dad.permit(tap, peth, S('mint(uint256)'));
        dad.permit(tap, peth, S('burn(uint256)'));
        dad.permit(tap, peth, S('burn(address,uint256)'));

        dad.permit(mom, vox, S("mold(bytes32,uint256)"));
        dad.permit(mom, vox, S("tune(uint256)"));
        dad.permit(mom, tub, S("mold(bytes32,uint256)"));
        dad.permit(mom, tap, S("mold(bytes32,uint256)"));
        dad.permit(mom, tub, S("setPip(address)"));
        dad.permit(mom, tub, S("setPep(address)"));
        dad.permit(mom, tub, S("setVox(address)"));

        dad.setOwner(0);
        step += 1;
    }
}
