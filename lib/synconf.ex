defmodule Synconf do
  @base_path System.user_home
  def base do
    @base_path
  end
end

defmodule Ver do
  defstruct [:content, :parent, :timestamp]
end

defmodule Conf do
  defstruct path: "", versions: %{}, head: ""

  def start_link(filepath) do
    {:ok, content} = File.read(filepath)
    {:ok, stat} = File.stat(filepath)
    chksum = :crypto.hash(:sha, content)
    Agent.start_link(fn -> %Conf{path: filepath,
				 versions: %{chksum =>
				   %Ver{content: content,
					parent: nil,
					timestamp: stat.mtime}},
				 head: chksum}
    end)
  end

  def update?(conf) do
    c = Agent.get(conf, &(&1))
    {:ok, stat} = File.stat(c.path)
    if stat.mtime > c.versions[c.head].timestamp do
      {:ok, content} = File.read(c.path)
      :crypto.hash(:sha, content) != c.head
    else
      false
    end
  end
end

