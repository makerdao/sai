setup() {
  # this protects us against accidentally running tests on mainnet
  [ "$(seth chain)" == "kovan" ]
}
