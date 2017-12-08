pragma solidity ^0.4.18;

import "ds-test/test.sol";
import './fab.sol';

contract BinTest is DSTest {
    GemFab gemFab;
    VoxFab voxFab;
    TubFab tubFab;
    TapFab tapFab;
    TopFab topFab;
    MomFab momFab;
    DadFab dadFab;

    DaiFab daiFab;

    DSToken gem;
    DSToken gov;
    DSValue pip;
    DSValue pep;
    address pit;

    function setUp() public {
        gemFab = new GemFab();
        voxFab = new VoxFab();
        tubFab = new TubFab();
        tapFab = new TapFab();
        topFab = new TopFab();
        momFab = new MomFab();
        dadFab = new DadFab();

        daiFab = new DaiFab(gemFab, voxFab, tubFab, tapFab, topFab, momFab, dadFab);

        gem = new DSToken('GEM');
        gov = new DSToken('GOV');
        pip = new DSValue();
        pep = new DSValue();
        pit = address(0x123);
    }

    function testMake() public {
        uint startGas = msg.gas;
        daiFab.makeTokens();
        uint endGas = msg.gas;
        log_named_uint('Make Tokens', startGas - endGas);

        startGas = msg.gas;
        daiFab.makeVoxTub(gem, gov, pip, pep, pit);
        endGas = msg.gas;
        log_named_uint('Make Vox Tub', startGas - endGas);

        startGas = msg.gas;
        daiFab.makeTapTop();
        endGas = msg.gas;
        log_named_uint('Make Tap Top', startGas - endGas);

        startGas = msg.gas;
        DSRoles authority = new DSRoles();
        authority.setRootUser(this, true);
        daiFab.configAuth(authority);
        endGas = msg.gas;
        log_named_uint('Config Auth', startGas - endGas);
    }
}
