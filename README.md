`sai` is a simple, single collateral, stable coin that is dependent on a
trusted oracle and has a kill-switch.

There are three tokens in the system:

- `gem`: collateral, e.g. ETH
- `sai`: the stablecoin
- `skr`: a claim to locked collateral

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

`sai` is fee free currently (FIXME). If there were fees, they would go
into the `sai` balance of the `tub` (known as `joy`). `joy` is sold off
with `boom` in exchange for `skr`, which is burned.


### Settlement

`sai` can be shutdown with `kill`, after which `sai` and `skr` can be
exchanged for `gems` via `save`. All outstanding `cups` are liquidated
and the *entire pool of `gem`* is tapped to redeem `sai` at their face
value. Any remaining `gems` are shared between `skr` holders.

Practically this means that if the system is undercollateralized on
`kill`, holders of free `skr` will have their `gem` share diluted as
much as necessary to make `sai` whole. *`skr` is a risk bearing token*.

Excess collateral contained within a single `cup` can be reclaimed with
`save(cup)`.


### glossary

#### tokens

- `SAI`: stablecoin
- `SIN`: debt (negative SAI)
- `SKR`: vote / lock-collateral coin
- `GEM`: true raw collateral

#### state variables

- `JOY`: surplus `sai` owned by the system
- `WOE`: bad debt owned by the system

#### abstract concepts

- `REF`: external asset (e.g. SDR, USD)

#### external data

- `TAG`: REF/GEM ratio
