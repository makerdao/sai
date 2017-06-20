
`sai` is a simple single-collateral stablecoin that is dependent on a
trusted oracle address and has a kill-switch.

There are three tokens in the system:

- `gem`: externally valuable token e.g. ETH
- `skr`: a claim to locked `gem`s
- `sai`: the stablecoin, a variable claim on some quantity of `gem`s

Collateral holders deposit their collateral using `join` and receive
`skr` tokens proportional to their deposit. `skr` can be redeemed for
collateral with `exit`. You will get more or less `gem` tokens for each
`skr` depending whether the system made a profit or loss while you
were exposed.

The oracle updates the GEM:REF price feed. This is the only external
real-time input to the system.

`skr` is used as the direct backing collateral for CDPs. A prospective
issuer can `open` an empty position, `lock` some `skr` and then `draw`
some `sai`. Debt is covered with `wipe`. Collateral can be reclaimed
with `free` as long as the CDP remains "safe".

If the value of the collateral backing the CDP falls below the
liquidation ratio `mat`, the CDP is vulnerable to liquidation via
`bite`. On liquidation, the CDP `skr` collateral is sold off to cover
the `sai` debt.

Under-collateralized CDPs can be liquidated with `bite`. Liquidation is
immediate: backing `skr` is taken to cover the `sai` debt at the time of
`bite`, plus a liquidation fee (`axe`); any excess remains in the CDP.

`skr` seized from bad CDPs can be purchased with `bust`, in exchange for
`sai` at the current feed price. This `sai` pays down the bad CDP debt.

### Fees

Stability fee is continuously charged on all open cups according to `tax`.
It makes their debt (`tab`) increase over time.

### Settlement

`sai` can be shut down at a given price with `cage`, after which `sai`
and `skr` can be exchanged for `gems` via `cash`. All outstanding `cups`
are liquidated and the *entire pool* of `gem` is tapped to redeem `sai`
at their face value, as if the boom/bust trades were instantly settled
at the cage price.  Any remaining `gems` are shared between `skr`
holders.

Practically this means that if the system is undercollateralized on
`cage`, holders of free `skr` will have their `gem` share diluted as
much as necessary to make `sai` whole. *In other words, `skr` is a
risk bearing token*.

Excess collateral contained within a single `cup` can be reclaimed with
`bail(cup)`.


### `sai` glossary (`sai help`)
```
Read commands:

   air             get the amount of backing collateral
   axe             get the liquidation penalty
   chi             get the internal debt price
   cup             show the cup info
   fix             get the SAI settlement price
   fog             get the amount of skr pending liquidation
   gem             get the collateral token
   hat             get the debt ceiling
   ice             get the good debt
   ink             get the amount of skr collateral locked in a cup
   jar             get the collateral vault
   joy             get the amount of surplus sai
   lad             get the owner of a cup
   mat             get the liquidation ratio
   par             get the gem per skr price just before settlement
   per             get the current entry price (gem per skr)
   pie             get the amount of raw collateral
   pip             get the gem price feed
   pit             get the liquidator vault
   pot             get the good debt vault
   ray             parse and display a 27-decimal fixed-point number
   reg             get the tub stage ('register')
   rho             get the time of last drip
   sai             get the sai token
   sin             get the sin token
   skr             get the skr token
   tab             get the amount of debt in a cup
   tag             get the reference price (ref per gem)
   tax             get the stability fee
   tip             get the target price engine
   wad             parse and display a 18-decimal fixed-point number
   woe             get the amount of bad debt

Commands:

   bail            bail the gems out of a cup after cage
   bite            initiate liquidation of an undercollateral cup
   boom            buy some amount of sai to process joy (surplus)
   bust            sell some amount of sai to process woe (bad debt)
   cage            lock the system and initiate settlement
   cash            cash in sai balance for gems after cage
   chop            update the liquidation penalty
   cork            update the debt ceiling
   crop            update the stability fee
   cuff            update the liquidation ratio
   cupi            get the last cup id
   cups            list your cups
   draw            issue the specified amount of sai stablecoins
   drip            recalculate the internal debt price
   exit            sell SKR for gems
   free            remove excess SKR collateral from a cup
   give            transfer ownership of a cup
   help            print help about sai(1) or one of its subcommands
   join            buy SKR for gems
   lock            post additional SKR collateral to a cup
   open            create a new cup (collateralized debt position)
   safe            determine if a cup is safe
   shut            close a cup
   vent            mark caged tub as empty
   wipe            repay some portion of your existing sai debt
```

### `sai-lpc` glossary (`sai-lpc help`)
```
Read commands:

   alt             get the alt token
   gap             get the spread, charged on `take`
   lps             get the lps token (liquidity provider shares)
   per             get the lps per ref ratio
   pie             get the total pool value (in ref)
   pip             get the price feed (giving refs per alt)
   ref             get the ref token
   tag             get the current price (refs per alt)

Commands:

   exit            exit lpc pool, exchange lps for ref or alt
   help            print help about sai-lpc(1) or one of its subcommands
   jump            update the spread
   pool            enter lpc pool, get lps for ref or alt
   take            perform an exchange
```

### Sample interaction using `sai`

```bash
$ export ETH_FROM=0x(...)
$ export SAI_TUB=0x(...)

# Give the system access to our GEM (W-ETH), SKR and SAI balances
$ token approve $(sai gem) $(sai jar) $(seth --to-wei 1000000000 ETH)
$ token approve $(sai skr) $(sai jar) $(seth --to-wei 1000000000 ETH)
$ token approve $(sai sai) $(sai pot) $(seth --to-wei 1000000000 ETH)

# We need to have some GEM (W-ETH) balance to start with
$ token balance $(sai gem) $ETH_FROM
2.467935274974511817

# Join the system by exchanging some GEM (W-ETH) to SKR
$ sai join 2.2
Sending 2.200000000000000000 GEM to TUB...
$ token balance $(sai gem) $ETH_FROM
0.267935274974511817
$ token balance $(sai skr) $ETH_FROM
2.200000000000000000

# Open a new cup
$ sai open
Opening cup...
Opened cup 62

# We can list cups owned by us at all times
$ sai cups																
Your cups ...
62

# Lock some SKR collateral in the cup and then draw some SAI from it
$ sai --cup 62 lock 1.5													
Locking 1.500000000000000000 SKR in cup 62...
$ sai --cup 62 draw 89.0												
Drawing 89.000000000000000000 SAI from cup 62...
$ token balance $(sai skr) $ETH_FROM
0.700000000000000000
$ token balance $(sai sai) $ETH_FROM
89.000000000000000000

# We can examine the cup details, `tab` and `ink` representing
# the amount of debt and the amount of collateral respectively
$ sai --cup 62 cup														
cup id 62...
lad: 0x(...)
tab: 89.000000000000000000
ink: 1.500000000000000000

# We can check whether the cup is still safe
# (ie. whether the value of collateral locked is high enough)
$ sai --cup 62 safe
true

# At some point we will want to wipe our SAI debt
# which means we can also free the SKR collateral
$ sai --cup 62 wipe 59.0												
Wiping 59.000000000000000000 SAI from cup 62...
$ sai --cup 62 free 1.1													
Freeing 1.100000000000000000 SKR from cup 62...
$ token balance $(sai skr) $ETH_FROM
1.800000000000000000
$ token balance $(sai sai) $ETH_FROM
30.000000000000000000

# The `tab` and `ink` values have changed
$ sai --cup 62 cup
cup id 62...
lad: 0x(...)
tab: 30.000000000000000000
ink: 0.400000000000000000

# We can also `wipe` and `free` outstanding balances of SAI and SKR by calling `shut`
$ sai --cup 62 shut
Closing cup 62...

$ sai --cup 62 cup
cup id 62...
lad: 0x0000000000000000000000000000000000000000
tab: 0.000000000000000000
ink: 0.000000000000000000

# Exit the system by exchanging SKR back to GEM (W-ETH)
$ sai exit 2.2
Sending 2.200000000000000000 SKR to TUB...
$ token balance $(sai gem) $ETH_FROM
2.467935274974511817
$ token balance $(sai skr) $ETH_FROM
0.000000000000000000
```

### Current deployments

v1.0:

```bash
# sai deployment on ethlive from 527dc9b3d84fa460e95a16c2d640e1a9e98511be

export GEM=0xECF8F87f810EcF450940c9f60066b4a7a501d6A7
export SAI=0x2c6f750aac54239af9af6b85a3049f6ca535b507
export SIN=0x3ad977780f0ecd41bd564898ffd46418d198f8a1
export SKR=0x84f162e108238b3b3029ab106e4bab0635cbf197
export POT=0x411ea383b0e5936ce667f51772c82ee37e9e93b9
export TAG=0x729D19f657BD0614b4985Cf1D82531c67569197B
export MOM=0x15f73a951d029a29fb6729bbf5600ac1646f5605
export LPS=0x0d126cd55c7a0e7c1340c5d185a8f0d254c00c60
export LPC=0x20bdda5f938b3b7661776e158e5b91457d9a55b7
export SAI_TUB=0x9fcb310dbbe5667f0fe7b0ea0947f365a335be6a
```

```bash
# sai deployment on kovan from 9e1424c486742032f8fa7a049393a45638250cc5

export GEM=0x53eccc9246c1e537d79199d0c7231e425a40f896
export SAI=0x532f529aaa86058eb378aa837dcf479d38e84969
export SIN=0x1cf3633c3d21c203631695874fead514faee9579
export SKR=0x447719c661c078791b972929a2529ba2575983b5
export POT=0x59adcf176ed2f6788a41b8ea4c4904518e62b6a4
export TAG=0xd5fb49fde313db2deeddc90374772468eb44b973
export MOM=0x2c67395bbbd658c239f54fb99487aefbbcf95636
export LPS=0x1ff103858f7954a95df7d43a7d04ff23a926f4da
export LPC=0x3bd1eeeffcbd8c922cadd5d76b2182debb3ca5af
export SAI_TUB=0x97bf1ff371ceabbb9e821480d31dd743c4b71e0e
```

Stability fee:

```bash
# sai deployment on kovan from cea6929ec72e68818b11062cf7e106802eaa3cd0

export GEM=0x53eccc9246c1e537d79199d0c7231e425a40f896
export SAI=0xdc2c399da89454066cb954fc57e4c947d27c5b15
export SIN=0x6e6e645a57b44e7d6d1d81331723d7404ec23801
export SKR=0xaab5aaa562f8dd950a5b5d1af1182c467a96eb03
export POT=0x03ee537f862b3aa1ce4c503bf4346060233839e3
export TAG=0xd5fb49fde313db2deeddc90374772468eb44b973
export MOM=0x2c67395bbbd658c239f54fb99487aefbbcf95636
export LPS=0x1435a878c265dee1b15f304d165b8d6fdba4e359
export LPC=0x10e9b30978d7973f2d1dd3c1b31938ac95be5ca6
export SAI_TUB=0x557f7e5e83da53e570032f05128483b09c316bdf
```
