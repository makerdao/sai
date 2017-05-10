pragma solidity ^0.4.8;

import './tub.sol';


contract MayPayout {
    Tub     public tub;

    DSToken public sai;
    DSToken public skr;

    address public dap = 0x86DCcc025e63f34b5d4435274Eb3Ea1639c6D843;
    address public fer = 0x00Ca405026e9018c29c26Cb081DcC9653428bFe9;
    address public nik = 0x0048d6225D1F3eA4385627eFDC5B4709Cab4A21c;
    address public mar = 0x6F2A8Ee9452ba7d336b3fba03caC27f7818AeAD6;
    address public mat = 0x9553bE76e414F9F44BF1F91fa31b8e8477A87731;
    address public onc = 0x6C65fB326e7734Ba5508b5d043718288b43b9ed9;
    address public rev = 0xcfe7E1665b1B699319e328Fa2a2565D13D7F799d;

    uint128 public payout = 111580.83 ether;

    // Eth wrapper
    ERC20   public eth;

    uint128 constant WAD = 10 ** 18;
    uint128 constant RAY = 10 ** 27;

    function MayPayout(address tub_) {
        tub = Tub(tub_);

        eth = tub.gem();
        sai = tub.sai();
        skr = tub.skr();
    }

    // `price` is a *wad* quantity
    function exec(uint128 price) {
        assert(tub.owner() == address(this));
        eth.transferFrom(msg.sender, this, 2000 ether);

        tub.chop(RAY);
        tub.cork(payout);
        tub.cuff(3 * RAY / 2);

        eth.approve(tub, 2000 ether);
        tub.join(2000 ether);

        var cup = tub.open();
        skr.approve(tub, 2000 ether);
        tub.lock(cup, 2000 ether);

        // distribute
        tub.draw(cup, payout);
        sai.push(dap, 66550.00 ether);
        sai.push(fer,  1180.83 ether);
        sai.push(mat, 10000.00 ether);
        sai.push(mar, 10000.00 ether);
        sai.push(nik, 11000.00 ether);
        sai.push(onc, 10000.00 ether);
        sai.push(rev,  2850.00 ether);

        assert(sai.totalSupply() == payout);

        // kill
        tub.cage(price);
        // retrieve remaining skr from cup
        tub.bail(cup);

        // return collateral
        skr.approve(tub, skr.balanceOf(this));
        tub.exit(uint128(skr.balanceOf(this)));

        eth.transfer(msg.sender, eth.balanceOf(this));

        assert(sai.totalSupply() == payout);
        assert(skr.totalSupply() == 0);
        assert(eth.balanceOf(this) == 0);
    }
}
