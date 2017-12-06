pragma solidity ^0.4.18;

contract TokFabInterface {
    function newTok(bytes32) public returns (address);
}

contract VoxFabInterface {
    function newVox() public returns (address);
}

contract TubFabInterface {
    function newTub(address, address, address, address, address, address, address, address, address) public returns (address);
}

contract TapFabInterface {
    function newTap(address) public returns (address);
}

contract TubInterface {
    function turn (address) public;
}

contract TopFabInterface {
    function newTop(address, address) public returns (address);
}

contract MomFabInterface {
    function newMom(address, address, address) public returns (address);
}

contract DadFabInterface {
    function newDad() public returns (address);
}

contract AuthInterface {
    function setAuthority(address) public;
    function setOwner(address) public;
    function setUserRole(address, uint8, bool) public;
    function setRoleCapability(uint8, address, bytes4, bool) public;
}

contract Deployer {
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

    function Deployer(address tokFab_, address voxFab_, address tubFab_, address tapFab_, address topFab_, address momFab_, address dadFab_) public {
        tokFab = tokFab_;
        voxFab = voxFab_;
        tubFab = tubFab_;
        tapFab = tapFab_;
        topFab = topFab_;
        momFab = momFab_;
        dadFab = dadFab_;
    }

    function deployTokens() public {
        require(sai == 0x0 && sin == 0x0 && skr == 0x0);
        sai = TokFabInterface(tokFab).newTok('sai');
        sin = TokFabInterface(tokFab).newTok('sin');
        skr = TokFabInterface(tokFab).newTok('skr');
    }


    function deployVoxTub(address gem, address gov, address pip, address pep, address pit) public {
        require(sai != 0x0 && sin != 0x0 && skr != 0x0 && gem != 0x0 && gov != 0x0 && pip != 0x0 && pep != 0x0 && pit != 0x0);
        vox = VoxFabInterface(voxFab).newVox();
        tub = TubFabInterface(tubFab).newTub(sai, sin, skr, gem, gov, pip, pep, vox, pit);
    }

    function deployTapTop() public {
        require(tub != 0x0 && vox != 0x0);
        tap = TapFabInterface(tapFab).newTap(tub);
        TubInterface(tub).turn(tap);
        top = TopFabInterface(topFab).newTop(tub, tap);
    }

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(s));
    }

    function deployAuth() public {
        require(tub != 0x0 && tap != 0x0 && vox != 0x0);

        mom = MomFabInterface(momFab).newMom(tub, tap, vox);
        dad = DadFabInterface(dadFab).newDad();

        AuthInterface(vox).setAuthority(dad);
        AuthInterface(tub).setAuthority(dad);
        AuthInterface(tap).setAuthority(dad);
        AuthInterface(top).setAuthority(dad);

        AuthInterface(sai).setAuthority(dad);
        AuthInterface(sin).setAuthority(dad);
        AuthInterface(skr).setAuthority(dad);

        AuthInterface(vox).setOwner(0);
        AuthInterface(tub).setOwner(0);
        AuthInterface(tap).setOwner(0);
        AuthInterface(top).setOwner(0);

        AuthInterface(sai).setOwner(0);
        AuthInterface(sin).setOwner(0);
        AuthInterface(skr).setOwner(0);

        uint8 SYS = 0;
        uint8 TOP = 1;
        uint8 MOM = 2;

        AuthInterface(dad).setUserRole(top, TOP, true);
        AuthInterface(dad).setUserRole(mom, MOM, true);
        AuthInterface(dad).setUserRole(vox, SYS, true);
        AuthInterface(dad).setUserRole(tub, SYS, true);
        AuthInterface(dad).setUserRole(tap, SYS, true);

        AuthInterface(dad).setRoleCapability(TOP, tub, S('cage(uint256,uint256)'), true);
        AuthInterface(dad).setRoleCapability(TOP, tub, S('flow()'), true);
        AuthInterface(dad).setRoleCapability(TOP, tap, S('cage(uint256)'), true);

        AuthInterface(dad).setRoleCapability(MOM, vox, S('mold(bytes32,uint256)'), true);
        AuthInterface(dad).setRoleCapability(MOM, tub, S('mold(bytes32,uint256)'), true);
        AuthInterface(dad).setRoleCapability(MOM, tap, S('mold(bytes32,uint256)'), true);

        AuthInterface(dad).setRoleCapability(SYS, skr, S('mint(address,uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, skr, S('mint(uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, skr, S('burn(address,uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, skr, S('burn(uint256)'), true);

        AuthInterface(dad).setRoleCapability(SYS, sai, S('mint(address,uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, sai, S('mint(uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, sai, S('burn(address,uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, sai, S('burn(uint256)'), true);

        AuthInterface(dad).setRoleCapability(SYS, sin, S('mint(address,uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, sin, S('mint(uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, sin, S('burn(address,uint256)'), true);
        AuthInterface(dad).setRoleCapability(SYS, sin, S('burn(uint256)'), true);

        AuthInterface(dad).setOwner(0);
    }
}
