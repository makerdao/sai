
`sai` is a simple single-collateral stablecoin that is dependent on a
trusted oracle and has a kill-switch.

There are three tokens in the system:

- `gem`: externally valuable token e.g. ETH
- `skr`: a claim to locked `gem`s
- `sai`: the stablecoin, a variable claim on some quantity of `gem`s

Collateral holders deposit their collateral using `join` and receive
`skr` tokens proportional to their deposit. `skr` can be redeemed for
collateral with `exit`. You will get more or less `gem` tokens for each
`skr` depending whether the system made a profit or loss while you
were exposed.

The oracle updates the GEM:REF price feed using `mark`. This is the only
external real-time input to the system.

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

### Settlement

`sai` can be shut down at a given price with `cage`, after which `sai`
and `skr` can be exchanged for `gems` via `cash`. All outstanding `cups`
are liquidated and the *entire pool* of `gem` is tapped to redeem `sai`
at their face value, as if the boom/bust trades were instantly settled
at the cage price.  Any remaining `gems` are shared between `skr`
holders.

Practically this means that if the system is undercollateralized on
`cage`, holders of free `skr` will have their `gem` share diluted as
much as necessary to make `sai` whole. *`skr` is a risk bearing token*.

Excess collateral contained within a single `cup` can be reclaimed with
`bail(cup)`.


### glossary (`sai help`)
```
Read commands:

   air             get the amount of backing collateral
   axe             get the liquidation penalty
   fit             get the SKR settlement price
   fix             get the SAI settlement price
   fog             get the amount of skr pending liquidation
   gem             get the collateral token
   hat             get the debt ceiling
   hat             get the liquidation ratio
   ice             get the good debt
   ink             get how much skr collateral in a cup
   joy             get the amount of surplus sai
   lad             get the owner of a cup
   off             is the tub caged?
   per             get the current entry price (skr per gem)
   pie             get the amount of raw collateral
   ray             parse and display a 36-decimal fixed-point number
   sai             get the sai token
   sin             get the sin token
   sin             get the sin token
   skr             get the skr token
   tab             get how much debt in a cup
   tag             get the reference price (ref per gem)
   wad             parse and display a 18-decimal fixed-point number
   woe             get the amount of bad debt

Commands:

   bail            bail the gems out of a cup after kill
   bite            initiate liquidation of an undercollateral cup
   cage            lock the system and initiate settlement
   cash            cash in sai / skr balance for gems after kill
   chop            update the liquidation penalty
   cork            update the debt ceiling
   cuff            update the liquidation ratio
   cupi            get the last cup id
   draw            issue the specified amount of sai stablecoins
   exit            sell SKR
   free            remove excess SKR collateral from a cup
   give            transfer ownership of a cup
   help            print help about sai(1) or one of its subcommands
   join            buy SKR
   jump            redeem sai and SKR for gems (settlement mode only)
   lock            post additional SKR collateral to a cup
   mark            update the tag
   open            create a new cup (collateralized debt position)
   safe            determine if a cup is safe
   wipe            repay some portion of your existing sai debt


```
