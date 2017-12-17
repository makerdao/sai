


_Please note that this document temporarily refers to sai instead of dai and skr instead of peth. These are just different variable names and their functionality is identical to what is described in the latest Dai documentation._


`sai` is a simple single-collateral stablecoin that is dependent on a
trusted oracle address and has a kill-switch.

See the [developer documentation](DEVELOPING.md) for a more technical
overview.

There are four tokens in the system:

- `gem`: externally valuable token e.g. ETH
- `gov`: governance token e.g. MKR
- `skr`: a claim to locked `gem`s
- `sai`: the stablecoin, a variable claim on some quantity of `gem`s

Collateral holders deposit their collateral using `join` and receive
`skr` tokens proportional to their deposit. `skr` can be redeemed for
collateral with `exit`. You will get more or less `gem` tokens for each
`skr` depending whether the system made a profit or loss while you
were exposed.

The oracle updates the GEM:REF and GOV:REF price feeds. These are the
only external real-time input to the system.

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
`sai` at the `s2s` price. This `sai` pays down the bad CDP debt.

Any remaining Sai surplus (`joy`) can be purchased with `boom`, in
exchange for `skr` at the `s2s` price. This `skr` is burned.


### Fees

Stability fee is continuously charged on all open cups according to `tax`.
It makes their debt (`tab`) increase over time.

Governance fee is continuously charged on all open cups according to `fee`.
It makes their debt (`rap`) increase over time.

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
`bite(cup)`.


### `sai` glossary (`sai help`)
```
Actions:

   bite            initiate liquidation of an undercollateral cup
   boom            buy some amount of sai to process joy (surplus)
   bust            sell some amount of sai to process woe (bad debt)
   cage            lock the system and initiate settlement
   cash            cash in sai balance for gems after cage
   cupi            get the last cup id
   cups            list cups created by you
   draw            issue the specified amount of sai stablecoins
   drip            recalculate the internal debt price
   exit            sell SKR for gems
   free            remove excess SKR collateral from a cup
   give            transfer ownership of a cup
   heal            cancel debt
   help            print help about sai(1) or one of its subcommands
   join            buy SKR for gems
   lock            post additional SKR collateral to a cup
   open            create a new cup (collateralized debt position)
   prod            recalculate the accrued holder fee (par)
   safe            determine if a cup is safe
   setAxe          update the liquidation penalty
   setFee          update the governance fee
   setCap          update the debt ceiling
   setMat          update the liquidation ratio
   setTapGap       update the spread on `boom` and `bust`
   setTax          update the stability fee
   setTubGap       update the spread on `join` and `exit`
   setWay          update the holder fee (interest rate)
   shut            close a cup
   vent            process a caged tub
   wipe            repay some portion of your existing sai debt
   
Vars, Getters, Utils:

   air             get the amount of backing collateral
   axe             get the liquidation penalty
   caged           get time of cage event (= 0 if system is not caged)
   chi             get the internal debt price
   cup             show the cup info
   fee             get the governance fee
   fit             get the gem per skr settlement price
   fix             get the gem per sai settlement price
   fog             get the amount of skr pending liquidation
   gem             get the collateral token
   gov             get the governance token
   cap             get the debt ceiling
   ice             get the good debt
   ink             get the amount of skr collateral locked in a cup
   joy             get the amount of surplus sai
   lad             get the owner of a cup
   mat             get the liquidation ratio
   off             get the cage flag
   out             get the post cage exit flag
   par             get the accrued holder fee (ref per sai)
   per             get the current entry price (gem per skr)
   pie             get the amount of raw collateral
   pep             get the gov price feed
   pip             get the gem price feed
   pit             get the liquidator vault
   rap             get the amount of governance debt in a cup
   ray             parse and display a 27-decimal fixed-point number
   rho             get the time of last drip
   rhi             get the internal debt price (governance included)
   s2s             get the skr per sai rate (for boom and bust)
   sai             get the sai token
   sin             get the sin token
   skr             get the skr token
   tab             get the amount of debt in a cup
   tag             get the reference price (ref per skr)
   tapAsk          get the amount of skr in sai for bust
   tapBid          get the amount of skr in sai for boom
   tapGap          get the spread on `boom` and `bust`
   tau             get the time of last prod
   tax             get the stability fee
   tubAsk          get the amount of skr in gem for join
   tubBid          get the amount of skr in gem for exit
   tubGap          get the spread on `join` and `exit`
   vox             get the target price engine
   wad             parse and display a 18-decimal fixed-point number
   way             get the holder fee (interest rate)
   woe             get the amount of bad debt


```

### Sample interaction using `sai`

```bash
$ export ETH_FROM=0x(...)
$ export SAI_TUB=0x(...)

# Give the system access to our GEM (W-ETH), SKR and SAI balances
# so we can join()/exit() and also draw()/wipe() sai
$ token approve $(sai gem) $(sai tub) $(seth --to-wei 1000000000 ETH)
$ token approve $(sai skr) $(sai tub) $(seth --to-wei 1000000000 ETH)
$ token approve $(sai sai) $(sai tub) $(seth --to-wei 1000000000 ETH)

# If we also plan on using boom() and bust(), a different component
# (called `tap`) will need to have access to our SKR and SAI balances
$ token approve $(sai skr) $(sai tap) $(seth --to-wei 1000000000 ETH)
$ token approve $(sai sai) $(sai tap) $(seth --to-wei 1000000000 ETH)

# We need to have some GEM (W-ETH) balance to start with
$ token balance $(sai gem) $ETH_FROM
2.467935274974511817

# Join the system by exchanging some GEM (W-ETH) to SKR
$ sai join 2.2
Generating 2.200000000000000000 SKR depositing GEM...
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
ink: 1.500000000000000000
tab: 89.000000000000000000
rap: 0.000000000000000000

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
ink: 0.400000000000000000
tab: 30.000000000000000000
rap: 0.000000000000000000

# We can also `wipe` and `free` outstanding balances of SAI and SKR by calling `shut`
$ sai --cup 62 shut
Closing cup 62...

$ sai --cup 62 cup
cup id 62...
lad: 0x0000000000000000000000000000000000000000
ink: 0.000000000000000000
tab: 0.000000000000000000
rap: 0.000000000000000000

# Exit the system by exchanging SKR back to GEM (W-ETH)
$ sai exit 2.2
Sending 2.200000000000000000 SKR to TUB...
$ token balance $(sai gem) $ETH_FROM
2.467935274974511817
$ token balance $(sai skr) $ETH_FROM
0.000000000000000000
```

### Current deployments

v3.0:

```bash
# TODO: ADD NEW ADDRESSES (load-env)

export SAI_MULTISIG=0x2305576962e33102b01d8f3dfda2fa640137b15e
```

```bash
# TODO: ADD NEW ADDRESSES (load-env)

export SAI_MULTISIG=0xf24888d405776cc56d29e70448172380708bb7a5
```
