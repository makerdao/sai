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
    function newVox() public returns (SaiVox vox) {
        vox = new SaiVox(10 ** 27);
        vox.setOwner(msg.sender);
    }
}

contract TubFab {
    function newTub(DSToken sai, DSToken sin, DSToken skr, ERC20 gem, DSToken gov, DSValue pip, DSValue pep, SaiVox vox, address pit) public returns (SaiTub tub) {
        tub = new SaiTub(sai, sin, skr, gem, gov, pip, pep, vox, pit);
        tub.setOwner(msg.sender);
    }
}

contract TapFab {
    function newTap(SaiTub tub) public returns (SaiTap tap) {
        tap = new SaiTap(tub);
        tap.setOwner(msg.sender);
    }
}

contract TopFab {
    function newTop(SaiTub tub, SaiTap tap) public returns (SaiTop top) {
        top = new SaiTop(tub, tap);
        top.setOwner(msg.sender);
    }
}

contract MomFab {
    function newMom(SaiTub tub, SaiTap tap, SaiVox vox) public returns (SaiMom mom) {
        mom = new SaiMom(tub, tap, vox);
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

    DSToken public sai;
    DSToken public sin;
    DSToken public skr;

    SaiVox public vox;
    SaiTub public tub;
    SaiTap public tap;
    SaiTop public top;

    SaiMom public mom;
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
        sai = gemFab.newTok('DAI');
        sin = gemFab.newTok('SIN');
        skr = gemFab.newTok('PETH');
        sai.setName('Dai Stablecoin v1.0');
        sin.setName('SIN');
        skr.setName('Pooled Ether');
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
        tub = tubFab.newTub(sai, sin, skr, gem, gov, pip, pep, vox, pit);
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
        sai.setAuthority(dad);
        sai.setOwner(0);
        sin.setAuthority(dad);
        sin.setOwner(0);
        skr.setAuthority(dad);
        skr.setOwner(0);

        top.setAuthority(authority);
        top.setOwner(0);
        mom.setAuthority(authority);
        mom.setOwner(0);

        dad.permit(top, tub, S("cage(uint256,uint256)"));
        dad.permit(top, tub, S("flow()"));
        dad.permit(top, tap, S("cage(uint256)"));

        dad.permit(tub, skr, S('mint(address,uint256)'));
        dad.permit(tub, skr, S('burn(address,uint256)'));

        dad.permit(tub, sai, S('mint(address,uint256)'));
        dad.permit(tub, sai, S('burn(address,uint256)'));

        dad.permit(tub, sin, S('mint(address,uint256)'));

        dad.permit(tap, sai, S('mint(address,uint256)'));
        dad.permit(tap, sai, S('burn(address,uint256)'));
        dad.permit(tap, sai, S('burn(uint256)'));
        dad.permit(tap, sin, S('burn(uint256)'));

        dad.permit(tap, skr, S('mint(uint256)'));
        dad.permit(tap, skr, S('burn(uint256)'));
        dad.permit(tap, skr, S('burn(address,uint256)'));

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
