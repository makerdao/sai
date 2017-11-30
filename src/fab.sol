pragma solidity ^0.4.18;

import 'ds-token/token.sol';
import 'ds-guard/guard.sol';
import 'ds-value/value.sol';

import './mom.sol';

contract FabEvents {
    event LogContractCreated(address contractAddress);
}

contract TokFab is FabEvents {
    function newTok(DSGuard dad, bytes32 name) public returns (DSToken token) {
        token = new DSToken(name);
        LogContractCreated(token);
        token.setAuthority(dad);
        token.setOwner(0);
    }
}

contract VoxFab is FabEvents {
    function newVox(DSGuard dad) public returns (SaiVox vox) {
        vox = new SaiVox();
        LogContractCreated(vox);
        vox.setAuthority(dad);
        vox.setOwner(0);
    }
}

contract TapFab is FabEvents {
    function newTap(DSGuard dad, SaiTub tub) public returns (SaiTap tap) {
        tap = new SaiTap(tub);
        LogContractCreated(tap);
        dad.permit(tap, tub.sai(), bytes4(keccak256('burn(uint256)')));
        dad.permit(tap, tub.sin(), bytes4(keccak256('burn(uint256)')));

        dad.permit(tap, tub.skr(), bytes4(keccak256('mint(uint256)')));
        dad.permit(tap, tub.skr(), bytes4(keccak256('burn(uint256)')));
        dad.permit(tap, tub.skr(), bytes4(keccak256('burn(address,uint256)')));
        tap.setAuthority(dad);
    }
}

contract TubFab is FabEvents {
    function newTub(DSGuard dad, DSToken sai, DSToken sin, DSToken skr, DSToken gem, DSToken gov, DSValue pip, DSValue pep, SaiVox vox, address pit) public returns (SaiTub tub) {
        tub = new SaiTub(sai, sin, skr, gem, gov, pip, pep, vox, pit);
        LogContractCreated(tub);
        dad.permit(tub, skr, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, skr, bytes4(keccak256('burn(address,uint256)')));

        dad.permit(tub, sai, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, sai, bytes4(keccak256('burn(address,uint256)')));

        dad.permit(tub, sin, bytes4(keccak256('mint(address,uint256)')));
        dad.permit(tub, sin, bytes4(keccak256('mint(uint256)')));
        dad.permit(tub, sin, bytes4(keccak256('burn(uint256)')));
        tub.setAuthority(dad);
        tub.setOwner(0);
    }
}

contract TopFab is FabEvents {
    function newTop(DSGuard dad, SaiTub tub, SaiTap tap) public returns (SaiTop top) {
        top = new SaiTop(tub, tap);
        LogContractCreated(top);
        dad.permit(top, tub, bytes4(keccak256("cage(uint256,uint256)")));
        dad.permit(top, tub, bytes4(keccak256("flow()")));
        dad.permit(top, tap, bytes4(keccak256("cage(uint256)")));
        top.setAuthority(dad);
        top.setOwner(0);
    }
}

contract MomFab is FabEvents {
    function newMom(DSGuard dad, SaiTub tub, SaiTap tap, SaiVox vox) public returns (SaiMom mom) {
        mom = new SaiMom(tub, tap, vox);
        LogContractCreated(mom);
        dad.permit(mom, vox, bytes4(keccak256("mold(bytes32,uint256)")));
        dad.permit(mom, tub, bytes4(keccak256("mold(bytes32,uint256)")));
        dad.permit(mom, tap, bytes4(keccak256("mold(bytes32,uint256)")));
    }
}

contract DadFab is FabEvents {
    function newDad(TapFab tapFab, TubFab tubFab, TopFab topFab, MomFab momFab) public returns (DSGuard dad) {
        dad = new DSGuard();
        LogContractCreated(dad);
        dad.permit(tapFab, dad, bytes4(keccak256("permit(address,address,bytes32)")));
        dad.permit(tubFab, dad, bytes4(keccak256("permit(address,address,bytes32)")));
        dad.permit(topFab, dad, bytes4(keccak256("permit(address,address,bytes32)")));
        dad.permit(momFab, dad, bytes4(keccak256("permit(address,address,bytes32)")));
        dad.setAuthority(dad);
        dad.setOwner(0);
    }
}
