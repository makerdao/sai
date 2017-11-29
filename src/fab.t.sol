pragma solidity ^0.4.18;

import "ds-test/test.sol";
import './fab.sol';

contract FabTest is DSTest {
    TokFab tokFab;
    VoxFab voxFab;
    TapFab tapFab;
    TubFab tubFab;
    TopFab topFab;
    MomFab momFab;
    DadFab dadFab;

    DSToken gem;
    DSToken gov;
    DSToken sai;
    DSToken sin;
    DSToken skr;
    DSValue pip;
    DSValue pep;
    address pit;
    SaiVox vox;
    SaiTap tap;
    SaiTub tub;
    SaiTop top;
    SaiMom mom;
    DSGuard dad;

    function setUp() public {
        tokFab = new TokFab();
        voxFab = new VoxFab();
        tapFab = new TapFab();
        tubFab = new TubFab();
        topFab = new TopFab();
        momFab = new MomFab();
        dadFab = new DadFab();
    }

    function testDeploy() public {
        dad = dadFab.newDad(tapFab, tubFab, topFab, momFab);

        gem = new DSToken('GEM');
        gov = new DSToken('GOV');
        pip = new DSValue();
        pep = new DSValue();
        pit = address(0x123);

        sai = tokFab.newTok(dad, 'DAI');
        sin = tokFab.newTok(dad, 'SIN');
        skr = tokFab.newTok(dad, 'SKR');
        vox = voxFab.newVox(dad);
        tap = tapFab.newTap(dad, sai, sin, skr);
        tub = tubFab.newTub(dad, sai, sin, skr, gem, gov, pip, pep, vox, tap, pit);
        tapFab.turn(tap, tub);
        top = topFab.newTop(dad, tub, tap);
        mom = momFab.newMom(dad, tub, tap, vox);
    }
}
