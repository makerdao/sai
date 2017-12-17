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

    DSRoles authority;

    function setUp() public {
        gemFab = new GemFab();
        voxFab = new VoxFab();
        tubFab = new TubFab();
        tapFab = new TapFab();
        topFab = new TopFab();
        momFab = new MomFab();
        dadFab = new DadFab();

        uint startGas = msg.gas;
        daiFab = new DaiFab(gemFab, voxFab, tubFab, tapFab, topFab, momFab, dadFab);
        uint endGas = msg.gas;
        log_named_uint('Deploy DaiFab', startGas - endGas);

        gem = new DSToken('GEM');
        gov = new DSToken('GOV');
        pip = new DSValue();
        pep = new DSValue();
        pit = address(0x123);
        authority = new DSRoles();
        authority.setRootUser(this, true);
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
        daiFab.configParams();
        endGas = msg.gas;
        log_named_uint('Config Params', startGas - endGas);

        startGas = msg.gas;
        daiFab.verifyParams();
        endGas = msg.gas;
        log_named_uint('Verify Params', startGas - endGas);

        startGas = msg.gas;
        daiFab.configAuth(authority);
        endGas = msg.gas;
        log_named_uint('Config Auth', startGas - endGas);
    }

    function testFailStep() public {
        daiFab.makeTokens();
        daiFab.makeTokens();
    }

    function testFailStep2() public {
        daiFab.makeTokens();
        daiFab.makeTapTop();
    }

    function testFailStep3() public {
        daiFab.makeTokens();
        daiFab.makeVoxTub(gem, gov, pip, pep, pit);
        daiFab.makeTapTop();
        daiFab.makeVoxTub(gem, gov, pip, pep, pit);
    }

    function testFailStep4() public {
        daiFab.makeTokens();
        daiFab.makeVoxTub(gem, gov, pip, pep, pit);
        daiFab.makeTapTop();
        daiFab.configAuth(authority);
        daiFab.makeTokens();
    }
}
