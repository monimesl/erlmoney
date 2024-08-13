defmodule Money do
  import Kernel, except: [abs: 1]

  @moduledoc """
  Elixir's implementation of Fowler's Money pattern: https://martinfowler.com/eaaCatalog/money.html
  Defines a `Money` struct that store the value with method to manipulate it.
  Note.
    The value is stored in the currency's sub_unit_count. e.g "SLE 1" is stored as 100 cent.
    Cases where arithmetic operations produce a floating number, the banker's rounding algorithm
    is used to round to the nearest integer: https://rounding.to/understanding-the-bankers-rounding

  ## Examples

      iex> money = Money.new(250)     ## same as Le2.5 assuming the currency is Leone
      %Money{value: 250}
      iex> money = Money.add(money, 900)    ## add 900 cent (SLE 9)
      %Money{value: 1150}  ## same as Le11.50  assuming the currency is Leone
  """

  @type t :: %__MODULE__{
          # the value is stored as a multiple of
          # the generalized subunits - i.e multiple of 10^9 - billions
          value: integer
        }

  defstruct value: 0

  @spec new(integer) :: t
  @doc """
  Create a new `Money` struct from currency sub-units (cents)

  ## Examples
      iex> Money.new(1_000_00)
      %Money{value: 1_000_00}
  """
  def new(%Decimal{} = d),
    do: new(d |> Decimal.to_integer())

  def new(value) when is_integer(value),
    do: %Money{value: value}

  def new(value) when is_binary(value) do
    try do
      new(String.to_integer(value))
    rescue
      _ -> {:error, :invalid_money_value}
    end
  end

  def value(%Money{value: value}) do
    value
  end

  @spec compare(t, t) :: -1 | 0 | 1
  @doc ~S"""
  Compares two `Money` structs value and returns -1 if the
  first is smaller, 1 if the first is larger or 0 if they're equal

  ## Examples

      iex> Money.compare(Money.new(100), Money.new(100))
      0

      iex> Money.compare(Money.new(100), Money.new(101))
      -1

      iex> Money.compare(Money.new(101), Money.new(100))
      1

  """
  def compare(%Money{} = a, %Money{} = b) do
    case a.value - b.value do
      x when x < 0 -> -1
      x when x == 0 -> 0
      x when x > 0 -> 1
    end
  end

  @spec zero?(t) :: boolean
  @doc ~S"""
  Returns true if the value of a `Money` struct is zero

  ## Examples

      iex> Money.zero?(Money.new(0))
      true

      iex> Money.zero?(Money.new(100))
      false

  """
  def zero?(%Money{value: value}) do
    value == 0
  end

  @spec positive?(t) :: boolean
  @doc ~S"""
  Returns true if the value of a `Money` is greater than zero

  ## Examples

      iex> Money.positive?(Money.new(0))
      false

      iex> Money.positive?(Money.new(1000))
      true

      iex> Money.positive?(Money.new(-1000))
      false

  """
  def positive?(%Money{value: value}) do
    value > 0
  end

  @spec negative?(t) :: boolean
  @doc ~S"""
  Returns true if the value of a `Money` is less than zero

  ## Examples

      iex> Money.negative?(Money.new(0))
      false

      iex> Money.negative?(Money.new(1000))
      false

      iex> Money.negative?(Money.new(-1000))
      true

  """
  def negative?(%Money{value: value}) do
    value < 0
  end

  @spec equals?(t, t) :: boolean
  @doc ~S"""
  Returns true if two `Money` are equal that's, they are of the same value

  ## Examples

      iex> Money.equals?(Money.new(1000), Money.new(1000))
      true

      iex> Money.equals?(Money.new(1000), Money.new(1500))
      false

      iex> Money.equals?(Money.new(1000), Money.new(1000, :USD))
      false

  """
  def equals?(%Money{value: value}, %Money{value: value}), do: true
  def equals?(%Money{}, %Money{}), do: false

  @spec neg(t) :: t
  @doc ~S"""
  Returns a `Money` with the value negated.
  If the value is already negative, the `Money` is returned.

  ## Examples

      iex> Money.new(100) |> Money.neg
      %Money{value: -100}

      iex> Money.new(-100) |> Money.neg
      %Money{value: -100}

  """
  def neg(%Money{value: value}) when value < 0,
    do: %Money{value: value}

  def neg(%Money{value: value}),
      do: %Money{value: -value}

  @spec pos(t) :: t
  @doc ~S"""
  Returns a `Money` with the value made positive.

  ## Examples

      iex> Money.new(100) |> Money.pos
      %Money{value: 100}

      iex> Money.new(-100) |> Money.pos
      %Money{value: 100}

  """
  def pos(%Money{value: value}) when value > 0,
      do: %Money{value: value}

  def pos(%Money{value: value}),
      do: %Money{value: -value}

  @spec abs(t) :: t
  @doc ~S"""
  Returns a `Money` with the arithmetical absolute of the value.

  ## Examples

      iex> Money.new(-100) |> Money.abs
      %Money{value: 100}

      iex> Money.new(100) |> Money.abs
      %Money{value: 100}

  """
  def abs(%Money{value: value}),
    do: %Money{value: Kernel.abs(value)}

  @spec add(t, t) :: t
  @doc ~S"""
  Adds `Money` to another `Money`
  If the argument is integer, it's taken to be represented in the sub-units to add.
  """
  def add(%Money{value: a}, %Money{value: b}),
    do: Money.new(a + b)

  def add(%Money{value: value}, argument) when is_integer(argument),
    do: Money.new(value + argument)

  @spec subtract(t, t) :: t
  @doc ~S"""
  Subtracts `Money` from another `Money`
  If the argument is integer, it's taken to be represented in the sub-units to add.
  """
  def subtract(%Money{value: a}, %Money{value: b}),
    do: Money.new(a - b)

  def subtract(%Money{value: value}, argument) when is_integer(argument),
    do: Money.new(value - argument)

  @spec multiply(t, integer | float | Decimal.t()) :: t
  @doc ~S"""
  Multiplies `Money`, with an integer or float multiplier
  """
  def multiply(%Money{} = m, multiplier) when is_integer(multiplier),
    do: multiply(m, Decimal.new(multiplier))

  def multiply(%Money{} = m, multiplier) when is_float(multiplier),
    do: multiply(m, Decimal.from_float(multiplier))

  def multiply(%Money{value: value}, %Decimal{} = multiplier),
    do:
      value
      |> Decimal.new()
      |> Decimal.mult(multiplier)
      |> decimal_to_money

  @spec divide(t, integer | float | Decimal.t()) :: t
  @doc ~S"""
  Divides `Money`, with an integer or float divisor and rounds the resulting money
  using banker's rounding: https://rounding.to/understanding-the-bankers-rounding
  """
  def divide(%Money{} = m, divisor) when is_integer(divisor),
    do: divide(m, Decimal.new(divisor))

  def divide(%Money{} = m, divisor) when is_float(divisor),
    do: divide(m, Decimal.from_float(divisor))

  def divide(%Money{value: value}, %Decimal{} = divisor),
    do:
      value
      |> Decimal.new()
      |> Decimal.div(divisor)
      |> decimal_to_money

  @spec split(t, integer) :: [t]
  @doc ~S"""
  Splits up `Money` by into specified number of parts.
  For value that cannot be divided uniformly among the parts,
  the leftover pennies are shared among the parties in a round-robin fashion.
  ## Examples

      iex> Money.split(Money.new(500), 2)
      [%Money{value: 250}, %Money{value: 250}]

      iex> Money.split(Money.new(500), 3)
      [%Money{value: 167}, %Money{value: 167}, %Money{value: 166}]

  """
  def split(%Money{value: value}, denominator) when is_integer(denominator) do
    value = div(value, denominator)
    rem = rem(value, denominator)
    split0(value, rem, denominator, [])
  end

  defp decimal_to_money(%Decimal{} = d),
    do:
      d
      |> Decimal.round(0, :half_even)
      |> Decimal.to_integer()
      |> Money.new()

  @spec to_decimal(t) :: Decimal.t()
  @doc ~S"""
  Converts a `Money` struct to a `Decimal` representation

  """
  def to_decimal(%Money{} = money) do
    Decimal.new(money.value)
  end

  defp split0(_value, _rem, 0, acc),
    do:
      acc
      |> Enum.reverse()

  defp split0(value, 0, count, acc) do
    acc = [new(current_split(value, 0, count)) | acc]
    count = decrement_value_only(count)
    split0(value, 0, count, acc)
  end

  defp split0(value, rem, count, acc) do
    acc = [new(current_split(value, rem, count)) | acc]
    rem = decrement_value_only(rem)
    count = decrement_value_only(count)
    split0(value, rem, count, acc)
  end

  defp current_split(0, -1, count) when count > 0, do: -1
  defp current_split(value, 0, _count), do: value
  defp current_split(value, _rem, _count), do: increment_value_only(value)

  defp increment_value_only(v) when v >= 0, do: v + 1
  defp increment_value_only(v) when v < 0, do: v - 1
  defp decrement_value_only(v) when v >= 0, do: v - 1
  defp decrement_value_only(v) when v < 0, do: v + 1

  defimpl String.Chars, for: Money do
    def to_string(m) do
      "#{m.value}"
    end
  end
end
