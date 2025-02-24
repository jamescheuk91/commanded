defmodule Commanded.Event.EventHandlerMacroTest do
  use ExUnit.Case

  alias Commanded.Event.IgnoredEvent
  alias Commanded.ExampleDomain.BankAccount.AccountBalanceHandler
  alias Commanded.ExampleDomain.BankAccount.Events.{BankAccountOpened, MoneyDeposited}
  alias Commanded.ExampleDomain.BankApp
  alias Commanded.Helpers.{EventFactory, Wait}

  describe "event handler" do
    setup do
      start_supervised!(BankApp)
      handler = start_supervised!(AccountBalanceHandler)

      Wait.until(fn ->
        assert AccountBalanceHandler.subscribed?()
      end)

      [handler: handler]
    end

    test "should handle published events", %{handler: handler} do
      recorded_events =
        [
          %BankAccountOpened{account_number: "ACC123", initial_balance: 1_000},
          %MoneyDeposited{amount: 50, balance: 1_050},
          %IgnoredEvent{name: "ignored"}
        ]
        |> EventFactory.map_to_recorded_events()

      send(handler, {:events, recorded_events})

      Wait.until(fn ->
        assert AccountBalanceHandler.current_balance() == 1_050
      end)
    end
  end
end
