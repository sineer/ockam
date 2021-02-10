if Code.ensure_loaded?(:ranch) do
  defmodule Ockam.Transport.TCP.Listener do
    @moduledoc false

    use Ockam.Worker

    @tcp 1

    @doc false
    @impl true
    def setup(options, state) do
      ip = Keyword.get_lazy(options, :ip, &default_ip/0)
      state = Map.put(state, :ip, ip)

      port = Keyword.get_lazy(options, :port, &default_port/0)
      state = Map.put(state, :port, port)

      route_outgoing = Keyword.get(options, :route_outgoing, false)

      ref = make_ref()
      transport = :ranch_tcp
      transport_options = [port: port]
      protocol = __MODULE__.Handler
      protocol_options = []

      with {:ok, _apps} <- Application.ensure_all_started(:ranch),
           :ok <- start_listener(ref, transport, transport_options, protocol, protocol_options),
           :ok <- setup_routed_message_handler(route_outgoing, state.address) do
        {:ok, state}
      end
    end

    defp start_listener(ref, transport, transport_options, protocol, protocol_options) do
      r = :ranch.start_listener(ref, transport, transport_options, protocol, protocol_options)

      case r do
        {:ok, _child} -> :ok
        {:ok, _child, _info} -> :ok
        {:error, reason} -> {:error, {:could_not_start_ranch_listener, reason}}
      end
    end

    defp setup_routed_message_handler(true, listener) do
      handler = fn message -> handle_routed_message(listener, message) end

      with :ok <- Router.set_message_handler(@tcp, handler),
           :ok <- Router.set_message_handler(Ockam.Transport.TCPAddress, handler) do
        :ok
      end
    end

    defp setup_routed_message_handler(_something_else, _listener), do: :ok

    defp handle_routed_message(listener, message) do
      Node.send(listener, message)
    end

    defp default_ip, do: {127, 0, 0, 1}
    defp default_port, do: 4000
  end

  defmodule Ockam.Transport.TCP.Listener.Handler do
    @moduledoc false

    def start_link(ref, socket, transport, _opts) do
      pid = :proc_lib.spawn_link(__MODULE__, :init, [ref, socket, transport])
      {:ok, pid}
    end

    def init(ref, socket, transport) do
      :ok = :ranch.handshake(ref)
      :ok = transport.setopts(socket, [{:active, true}, {:nodelay, true}, {:reuseaddr, true}])
      :gen_server.enter_loop(__MODULE__, [], %{socket: socket, transport: transport})
    end

    def handle_info({:tcp, socket, data}, %{socket: socket, transport: _transport} = state) do
      IO.puts("#{inspect(data)}")
      # @TODO: do something other than echo
      # transport.send(socket, data)
      {:noreply, state}
    end

    def handle_info({:tcp_closed, socket}, %{socket: socket, transport: transport} = state) do
      IO.puts("Closing")
      transport.close(socket)
      {:stop, :normal, state}
    end
  end
end
