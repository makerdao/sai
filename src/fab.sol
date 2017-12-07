pragma solidity ^0.4.18;

import "ds-auth/auth.sol";
import 'ds-token/token.sol';
import 'ds-guard/guard.sol';
import 'ds-roles/roles.sol';
import 'ds-value/value.sol';

import './mom.sol';

contract TokFab {
    function newTok(bytes32 name) public returns (DSToken token) {
        token = new DSToken(name);
        token.setOwner(msg.sender);
    }
}

contract VoxFab {
    function newVox() public returns (SaiVox vox) {
        vox = new SaiVox();
        vox.setOwner(msg.sender);
    }
}

contract TubFab {
    function newTub(DSToken sai, DSToken sin, DSToken skr, DSToken gem, DSToken gov, DSValue pip, DSValue pep, SaiVox vox, address pit) public returns (SaiTub tub) {
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

contract Interface {
    function newTok(bytes32) public returns (address);
    function newVox() public returns (address);
    function newTub(address, address, address, address, address, address, address, address, address) public returns (address);
    function newTap(address) public returns (address);
    function turn (address) public;
    function newTop(address, address) public returns (address);
    function newMom(address, address, address) public returns (address);
    function newDad() public returns (address);
    function setAuthority(address) public;
    function setOwner(address) public;
    // function setUserRole(address, uint8, bool) public;
    // function setRoleCapability(uint8, address, bytes4, bool) public;
    function permit(address, address, bytes32) public;
}

contract DaiFab is DSAuth {
    address tokFab;
    address voxFab;
    address tapFab;
    address tubFab;
    address topFab;
    address momFab;
    address dadFab;

    address public sai;
    address public sin;
    address public skr;

    address public vox;
    address public tub;
    address public tap;
    address public top;

    address public mom;
    address public dad;

    function DaiFab(address tokFab_, address voxFab_, address tubFab_, address tapFab_, address topFab_, address momFab_, address dadFab_) public {
        tokFab = tokFab_;
        voxFab = voxFab_;
        tubFab = tubFab_;
        tapFab = tapFab_;
        topFab = topFab_;
        momFab = momFab_;
        dadFab = dadFab_;
    }

    function makeTokens() public auth {
        require(sai == 0x0 &&
                sin == 0x0 &&
                skr == 0x0);
        sai = Interface(tokFab).newTok('sai');
        sin = Interface(tokFab).newTok('sin');
        skr = Interface(tokFab).newTok('skr');
    }


    function makeVoxTub(address gem, address gov, address pip, address pep, address pit) public auth {
        require(sai != 0x0 &&
                sin != 0x0 &&
                skr != 0x0 &&
                gem != 0x0 &&
                gov != 0x0 &&
                pip != 0x0 &&
                pep != 0x0 &&
                pit != 0x0);
        vox = Interface(voxFab).newVox();
        tub = Interface(tubFab).newTub(sai, sin, skr, gem, gov, pip, pep, vox, pit);
    }

    function makeTapTop() public auth {
        require(tub != 0x0 &&
                vox != 0x0);
        tap = Interface(tapFab).newTap(tub);
        Interface(tub).turn(tap);
        top = Interface(topFab).newTop(tub, tap);
    }

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(s));
    }

    function configAuth(address authority) public auth {
        require(vox != 0x0 &&
                tub != 0x0 &&
                tap != 0x0 &&
                top != 0x0 &&
                authority != 0x0);

        mom = Interface(momFab).newMom(tub, tap, vox);
        dad = Interface(dadFab).newDad();

        Interface(vox).setAuthority(dad);
        Interface(vox).setOwner(0);
        Interface(tub).setAuthority(dad);
        Interface(tub).setOwner(0);
        Interface(tap).setAuthority(dad);
        Interface(tap).setOwner(0);
        Interface(sai).setAuthority(dad);
        Interface(sai).setOwner(0);
        Interface(sin).setAuthority(dad);
        Interface(sin).setOwner(0);
        Interface(skr).setAuthority(dad);
        Interface(skr).setOwner(0);

        Interface(top).setAuthority(authority);
        Interface(top).setOwner(0);
        Interface(mom).setAuthority(authority);
        Interface(mom).setOwner(0);

        Interface(dad).permit(top, tub, S("cage(uint256,uint256)"));
        Interface(dad).permit(top, tub, S("flow()"));
        Interface(dad).permit(top, tap, S("cage(uint256)"));

        Interface(dad).permit(tub, skr, S('mint(address,uint256)'));
        Interface(dad).permit(tub, skr, S('burn(address,uint256)'));

        Interface(dad).permit(tub, sai, S('mint(address,uint256)'));
        Interface(dad).permit(tub, sai, S('burn(address,uint256)'));

        Interface(dad).permit(tub, sin, S('mint(address,uint256)'));
        Interface(dad).permit(tub, sin, S('mint(uint256)'));
        Interface(dad).permit(tub, sin, S('burn(uint256)'));

        Interface(dad).permit(tap, sai, S('mint(address,uint256)'));
        Interface(dad).permit(tap, sai, S('burn(uint256)'));
        Interface(dad).permit(tap, sai, S('burn(address,uint256)'));
        Interface(dad).permit(tap, sin, S('burn(uint256)'));

        Interface(dad).permit(tap, skr, S('mint(uint256)'));
        Interface(dad).permit(tap, skr, S('burn(uint256)'));
        Interface(dad).permit(tap, skr, S('burn(address,uint256)'));

        Interface(dad).permit(mom, vox, S("mold(bytes32,uint256)"));
        Interface(dad).permit(mom, tub, S("mold(bytes32,uint256)"));
        Interface(dad).permit(mom, tap, S("mold(bytes32,uint256)"));

        Interface(dad).setOwner(0);
    }
}
