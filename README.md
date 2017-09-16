
`sai` is a simple single-collateral stablecoin that is dependent on a
trusted oracle address and has a kill-switch.

See the [developer documentation](DEVELOPING.md) for a more technical
overview.

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

Collected stability fees (`joy`) can be purchased with `boom`, in exchange for
`skr` at the `s2s` price. This `skr` gets burned which profits all `skr` holders.

`skr` seized from bad CDPs can be purchased with `bust`, in exchange for
`sai` at the `s2s` price. This `sai` pays down the bad CDP debt.

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
   fit             get the gem per skr settlement price
   fix             get the gem per sai settlement price
   fog             get the amount of skr pending liquidation
   gem             get the collateral token
   hat             get the debt ceiling
   ice             get the good debt
   ink             get the amount of skr collateral locked in a cup
   jar             get the collateral vault
   jar ask         get the price of gem per skr for join
   jar bid         get the price of gem per skr for exit
   jar gap         get the spread on `join` and `exit`
   joy             get the amount of surplus sai
   jug             get the sai / sin tracker
   lad             get the owner of a cup
   mat             get the liquidation ratio
   off             get the cage flag
   par             get the accrued holder fee (ref per sai)
   per             get the current entry price (gem per skr)
   pie             get the amount of raw collateral
   pip             get the gem price feed
   pit             get the liquidator vault
   pot             get the good debt vault
   ray             parse and display a 27-decimal fixed-point number
   rho             get the time of last drip
   s2s             get the skr per sai rate (for boom and bust)
   sai             get the sai token
   sin             get the sin token
   skr             get the skr token
   tab             get the amount of debt in a cup
   tag             get the reference price (ref per skr)
   tap ask         get the price of skr in sai for bust
   tap bid         get the price of skr in sai for boom
   tap gap         get the spread on `boom` and `bust`
   tau             get the time of last prod
   tax             get the stability fee
   tip             get the target price engine
   wad             parse and display a 18-decimal fixed-point number
   way             get the holder fee (interest rate)
   woe             get the amount of bad debt

Commands:

   bite            initiate liquidation of an undercollateral cup
   boom            buy some amount of sai to process joy (surplus)
   bust            sell some amount of sai to process woe (bad debt)
   cage            lock the system and initiate settlement
   cash            cash in sai balance for gems after cage
   chop            update the liquidation penalty
   coax            update the holder fee (interest rate)
   cork            update the debt ceiling
   crop            update the stability fee
   cuff            update the liquidation ratio
   cupi            get the last cup id
   cups            list cups created by you
   draw            issue the specified amount of sai stablecoins
   drip            recalculate the internal debt price
   exit            sell SKR for gems
   free            remove excess SKR collateral from a cup
   give            transfer ownership of a cup
   help            print help about sai(1) or one of its subcommands
   jar jump        update the spread on `join` and `exit`
   join            buy SKR for gems
   lock            post additional SKR collateral to a cup
   open            create a new cup (collateralized debt position)
   prod            recalculate the accrued holder fee (par)
   safe            determine if a cup is safe
   shut            close a cup
   tap jump        update the spread on `boom` and `bust`
   vent            process a caged tub
   wipe            repay some portion of your existing sai debt
```

### Sample interaction using `sai`

```bash
$ export ETH_FROM=0x(...)
$ export SAI_TUB=0x(...)

# Give the system access to our GEM (W-ETH), SKR and SAI balances
# so we can join()/exit() and also draw()/wipe() sai
$ token approve $(sai gem) $(sai jar) $(seth --to-wei 1000000000 ETH)
$ token approve $(sai skr) $(sai jar) $(seth --to-wei 1000000000 ETH)
$ token approve $(sai sai) $(sai pot) $(seth --to-wei 1000000000 ETH)

# If we also plan on using boom() and bust(), a different component
# (called `pit`) will need to have access to our SKR and SAI balances 
$ token approve $(sai skr) $(sai pit) $(seth --to-wei 1000000000 ETH)
$ token approve $(sai sai) $(sai pit) $(seth --to-wei 1000000000 ETH)

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

# We can list our cups at all times
$ sai cups																
Cups created by you...
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

v2.0:

```bash
# sai deployment on ethlive from 5a17c760d197710b43e0515453a5010c163d4813
# Sun 16 Jul 17:28:33 BST 2017

export SAI_GEM=0xECF8F87f810EcF450940c9f60066b4a7a501d6A7
export SAI_SAI=0x59adcf176ed2f6788a41b8ea4c4904518e62b6a4
export SAI_SIN=0x2c67395bbbd658c239f54fb99487aefbbcf95636
export SAI_SKR=0x97bf1ff371ceabbb9e821480d31dd743c4b71e0e
export SAI_JUG=0x9f6de35668006a721f93ce6a4e702ee2351f2423
export SAI_POT=0x0cbd5573275996b72e3e1e281d4acba8ae390940
export SAI_PIT=0xc61d918177970398234c7d4e9f9f2ab98ff4a581
export SAI_TIP=0x89f800b075b58dfa0729448c9cbb66c86b389aa3
export SAI_PIP=0x729D19f657BD0614b4985Cf1D82531c67569197B
export SAI_DAD=0x2ff889b73359f02d1cd4259aa6fe9d65e1b8854d
export SAI_MOM=0x1ff103858f7954a95df7d43a7d04ff23a926f4da
export SAI_JAR=0x3bd1eeeffcbd8c922cadd5d76b2182debb3ca5af
export SAI_TUB=0xe819300b6f3d0625632b47196233fe6671a59891
export SAI_TAP=0x897c798c096d44e511a275153da9de6139ebc249
export SAI_TOP=0x92bfd0e786e284429c96cf6a6e4a3ecf46fb3e9a

export SAI_MULTISIG=0x2305576962e33102b01d8f3dfda2fa640137b15e
```

```bash
# sai deployment on kovan from bc917f9c22264b39de92e19d1573c6bfd929c82d
# Mon 17 Jul 14:31:59 BST 2017

export SAI_GEM=0x53eccc9246c1e537d79199d0c7231e425a40f896
export SAI_SAI=0x228bf3d5be3ee4b80718b89b68069b023c32131e
export SAI_SIN=0x57e7f5c7f62ab03d47a8d5dc9f1de4cf873f2975
export SAI_SKR=0x38e53179c5ca9906fac05c558858c2ed1146036c
export SAI_JUG=0xe5f1c370cd10936afa6a6ac4cda66c67798fbc5b
export SAI_POT=0xb4ea493de22a64ad8f60ae8392f3af5d686be33e
export SAI_PIT=0xc1a05f74d3cbcdc21dace4923b547ffbac9b5d43
export SAI_TIP=0x429146506aa6ee613ba0724d207c0b3e344529c4
export SAI_PIP=0xA944bd4b25C9F186A846fd5668941AA3d3B8425F
export SAI_DAD=0x42ad0da36a8ad6a603626a5a9e1f1c7da3e1cd07
export SAI_MOM=0x40f1c47d3cadb0f0a7cac459543837a593e9117d
export SAI_JAR=0x098024b9da5ec4a23d747e2c70ff21181300ea9d
export SAI_TUB=0xb7ae5ccabd002b5eebafe6a8fad5499394f67980
export SAI_TAP=0xb9e0a196d2150a6393713e09bd79a0d39293ec13
export SAI_TOP=0xc25789084005dc4ed6be033a943f2c2f3efafcc1

export SAI_MULTISIG=0xf24888d405776cc56d29e70448172380708bb7a5
```
