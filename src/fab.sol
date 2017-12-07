pragma solidity ^0.4.18;

import 'ds-token/token.sol';
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
    function newDad() public returns (DSRoles dad) {
        dad = new DSRoles();
        dad.setOwner(msg.sender);
    }
}
