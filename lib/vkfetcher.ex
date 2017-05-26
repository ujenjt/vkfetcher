defmodule Vkfetcher do
  @apiBase "https://api.vk.com/method"
  @apiMethod "wall.get"
  @chunk 10

  def fetch_wall_chunk(offset, user_id) do
    body = HTTPotion.get(
      "#{@apiBase}/#{@apiMethod}",
      query: %{
        owner_id: user_id,
        extended: 0,
        filter: "owner",
        count: @chunk,
        offset: offset
      }
    ).body
    {:ok, data} = Poison.decode(body)
    [_count | posts] = data["response"]
    {:ok, Enum.map(posts, &(&1["text"]))}
  end

  def fetch_wall(options) do
    {:ok, file_pid} = File.open('wall.txt', [:write])

    fetch_texts(0, file_pid, options[:userId])

    File.close(file_pid)
  end

  def fetch_texts(offset, file_pid, user_id) do
    case fetch_wall_chunk(offset, user_id) do
      {:ok, []} ->
        :ok
      {:ok, texts} ->
        texts
        |> Enum.each( &(IO.binwrite(file_pid, &1 <> "\n")) )
        IO.puts("Chunk fetched #{offset}")
        :timer.sleep(1000)
        fetch_texts(offset +  @chunk, file_pid, user_id)
    end
  end

  def main(args) do
    args |> parse_args |> fetch_wall
  end

  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [userId: :string]
    )
    options
  end
end
