# Erlmoney

Elixir's implementation of Fowler's Money pattern: https://martinfowler.com/eaaCatalog/money.html

Defines a `Money` struct that store the value and have methods to manipulate it.
The value is stored in the currency's **sub_unit**. e.g. `"SLE 1"` is stored as `"100 cent"`.
Cases where arithmetic operations produce a floating number, the banker's rounding algorithm
is used to round to the nearest integer: https://rounding.to/understanding-the-bankers-rounding

## Why `erlmoney` 😊??
Well, Erlangers know; it's Elixir with Erlang style naming, the `erl` prefix.
