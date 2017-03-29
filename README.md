`sai` is a simple, single collateral, stable coin that is dependent on a
trusted oracle and has a kill-switch.

There are three tokens in the system:

- `gem`: collateral, e.g. ETH
- `sai`: the stablecoin
- `skr`: a claim to locked collateral

Collateral holders deposit their collateral using `join` and receive
`skr` tokens proportional to their deposit. `skr` can be redeemed for
collateral with `exit`.

The oracle updates the GEM:REF price feed using `mark`.

`skr` is used as the direct backing collateral for CDPs. A prospective
issuer can `open` an empty position, `lock` some `skr` and then `draw`
some `sai`. Debt is covered with `wipe`. Collateral can be reclaimed
with `free` as long as the CDP remains "safe". 

If the value of the collateral backing the CDP falls below the
liquidation ratio `mat`, the CDP is vulnerable to liquidation via
`bite`. On liquidation, the CDP `skr` collateral is sold off to cover
the `sai` debt.


### glossary

#### tokens

- `SAI`: stablecoin
- `SIN`: debt (negative SAI)
- `SKR`: vote / lock-collateral coin
- `GEM`: true raw collateral

#### abstract concepts

- `REF`: external asset (e.g. SDR, USD)

#### external data

- `TAG`: REF/GEM ratio
