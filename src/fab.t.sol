pragma solidity ^0.5.11;

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

        uint startGas = gasleft();
        daiFab = new DaiFab(gemFab, voxFab, tubFab, tapFab, topFab, momFab, dadFab);
        uint endGas = gasleft();
        emit log_named_uint('Deploy DaiFab', startGas - endGas);

        gem = new DSToken('GEM');
        gov = new DSToken('GOV');
        pip = new DSValue();
        pep = new DSValue();
        pit = address(0x123);
        authority = new DSRoles();
        authority.setRootUser(address(this), true);
    }

    function testMake() public {
        uint startGas = gasleft();
        daiFab.makeTokens();
        uint endGas = gasleft();
        emit log_named_uint('Make Tokens', startGas - endGas);

        startGas = gasleft();
        daiFab.makeVoxTub(gem, gov, pip, pep, pit);
        endGas = gasleft();
        emit log_named_uint('Make Vox Tub', startGas - endGas);

        startGas = gasleft();
        daiFab.makeTapTop();
        endGas = gasleft();
        emit log_named_uint('Make Tap Top', startGas - endGas);

        startGas = gasleft();
        daiFab.configParams();
        endGas = gasleft();
        emit log_named_uint('Config Params', startGas - endGas);

        startGas = gasleft();
        daiFab.verifyParams();
        endGas = gasleft();
        emit log_named_uint('Verify Params', startGas - endGas);

        startGas = gasleft();
        daiFab.configAuth(authority);
        endGas = gasleft();
        emit log_named_uint('Config Auth', startGas - endGas);
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
