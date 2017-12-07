pragma solidity ^0.4.18;

import "ds-test/test.sol";
import './fab.sol';
import './bin.sol';

contract BinTest is DSTest {
    TokFab tokFab;
    VoxFab voxFab;
    TubFab tubFab;
    TapFab tapFab;
    TopFab topFab;
    MomFab momFab;
    DadFab dadFab;

    Deployer deployer;

    DSToken gem;
    DSToken gov;
    DSValue pip;
    DSValue pep;
    address pit;
    // DSToken sai;
    // DSToken sin;
    // DSToken skr;

    // SaiVox vox;
    // SaiTap tap;
    // SaiTub tub;
    // SaiTop top;
    // SaiMom mom;
    // DSGuard dad;

    function setUp() public {
        tokFab = new TokFab();
        voxFab = new VoxFab();
        tubFab = new TubFab();
        tapFab = new TapFab();
        topFab = new TopFab();
        momFab = new MomFab();
        dadFab = new DadFab();

        deployer = new Deployer(tokFab, voxFab, tubFab, tapFab, topFab, momFab, dadFab);

        gem = new DSToken('GEM');
        gov = new DSToken('GOV');
        pip = new DSValue();
        pep = new DSValue();
        pit = address(0x123);
    }

    function testDeploy() public {
        uint startGas = msg.gas;
        deployer.deployTokens();
        uint endGas = msg.gas;
        log_named_uint('Deploy Tokens', startGas - endGas);

        startGas = msg.gas;
        deployer.deployVoxTub(gem, gov, pip, pep, pit);
        endGas = msg.gas;
        log_named_uint('Deploy Vox Tub', startGas - endGas);

        startGas = msg.gas;
        deployer.deployTapTop();
        endGas = msg.gas;
        log_named_uint('Deploy Tap Top', startGas - endGas);

        startGas = msg.gas;
        deployer.deployAuth(this, this);
        endGas = msg.gas;
        log_named_uint('Deploy Auth', startGas - endGas);
    }
}
