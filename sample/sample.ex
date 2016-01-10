# 商品一覧のチェックボックスからsubmitするようなものを考える
# カートの状態がセッションに保存されてるとかそういうのは考えない

# 在庫チェックの文脈もあるがとりあえず複数であればサンプルとしては十分そうなので考えない

# call(msg, from, state) -> {:reply, msg, new_state} | {:no_reply, new_state}
# cast(msg, state)       -> {:no_reply, new_state}

# HttpServer は Rack っぽいインターフェースにしてある。
# Plug の send_reqp/3 のインターフェースと同じ https://github.com/elixir-lang/plug

# [TODO] defcontext を共通化する方法が必要


defmodule ItemsHttpServer do
  use Context.GenServer
  use WebFramework

  def handle_call(request, from, state) do
    items = ConServer.call :items, {:get_list}
    html = render(:items, items)
    {:reply, [200, html]}
  end
end


defmodule PurchaseHttpServer do
  use Context.GenServer
  use WebFramework

  defcontext :login do
    # Check session status and return boolean
  end

  defcontext :contry do
    # Extract country from ip address
  end

  context login: true, payment: :normal do
    def handle_call(request, from, state) do
      item_ids = request.params[:item_ids]
      ConServer.cast :purchased_items, {:create, {user.id, item_ids}}
      cost = ConServer.call :items, {:calc_cost, item_ids}
      ConServer.call :payment, {:pay, cost}
      # # This may be a little complex, but We can wrap by function call, as followings.
      # PurchasedItemsServer.create(user.id, item_ids)
      # cost = ItemsServer.calc_cost(item_ids)
      # PaymentServer.pay(cost)
      {:reply, [200, 'Success']}
    end
  end

  context login: false do
    def handle_call(_) do
      {:reply, [300, 'Please Login', ['Location': login_url]]} # Redirect
    end
  end

  context payment: :abnormal do
    def handle_call(_) do
      {:reply, [500, 'Failure']}
    end
  end
end


defmodule PaymentServer do
  use Context.GenServer

  defcontext :payment
  
  def handle_cast({:notify_status, status}, _) do # call from external server
    switch_context :payment, status
    {:no_reply, _}
  end

  context payment: :normal do
    def handle_cast({:pay, cost}, state) do
      # pay
    end
  end

  # [Idea] rescue and switch_context

  context payment: :abnormal do
    def handle_cast({:pay, _}, state) do
      {:no_reply, state}
    end
  end
end


defmodule PurchasedItemsServer do
  def handle_cast({:create, {user_id, item_ids}}, state) do
    # Insert items to it's state
    {:no_reply, new_state}
  end

  def handle_cancel({:create, {user_id, item_ids}}, state) do
    # Remove items from it's state
    {:no_reply, new_state}
  end
end

defmodule ItemsServer do
  context :ja do
    def handle_call({:calc_cost, item_ids}, from, state) do
      # get items from item_ids and calculate the cost
      cost = Float.floor(cost * 0.08)
      {:reply, cost, state}
    end
  end

  context :en do
    def handle_call({:calc_cost, item_ids}, from, state) do
      # get items from item_ids and calculate the cost
      cost = Float.floor(cost * 0.175)
      {:reply, cost, state}
    end
  end

  def handle_call({:get_list}, from ,state) do
    # get items
    {:reply, items, state}
  end
end


# defmodule Server do
# # 1. Parse http request and translate to Request object
# # 2. Find a http server for the path using router
# # 3. Call the http server
# # 4. Translate the retrun value to http response and send it
# end

# defmodule Router do
# end

# defmodule RenderServer do
#   def call(template, locale) do
#     ...
#   end
# end

# defmodule WebApp do
#   def __use__(_) do
#     ...
#   end
  
#   def render() do
#   end
# end


# def Context do
#   def hash do
#     [
#       country: [:ja, :en, ...],
#       login: [:true, :false],
#       payment: [:normal, :abnormal],
#     ]
#   end
# end
