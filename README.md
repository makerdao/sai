yet another stablecoin

BTS style share token = collateral token

YAS -> decay against reference asset
SAY -> collateral / vote token
claims on ETH pool that inflates/deflates

simple inflation at current price to cover underwater CDP
interest rate -> highly leveraged issuers subsidize low leverage issuers

interest rate = decay rate, effective loan price is pegged to 0 rate loan in reference asset price

struct Config {
    penalty // applies up to this much penalty as long as ccp is solvent
    reward // gives this much to cat no matter what
    feed 
}

struct State {
    token say
    token yas
}

struct CCP {
    address lad;
    uint say;
    uint yas;
    uint rum; // for virtual  uint sin;
}

lock(ccpID, amt)
free(ccpID, amt)
draw(ccpID, amt)
wipe(ccpID, amt)

bite(ccpID)

kill(true price)
