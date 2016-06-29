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
  defstruct path: "", head: "", versions: %{}

  def new(filepath) do
    with {:ok, content} <- File.read(filepath),
	 {:ok, stat} <- File.stat(filepath),
	   chksum = :crypto.hash(:sha, content),
      do: %Conf{path: filepath,
		head: chksum,
		versions: %{chksum =>
		  %Ver{content: content,
		       parent: nil,
		       timestamp: stat.mtime}}}

  end

  def update?(conf) do
    {:ok, stat} = File.stat(conf.path)
    head_ver = conf.versions[conf.head].timestamp
    if stat.mtime > head_ver do
      {:ok, content} = File.read(conf.path)
      :crypto.hash(:sha, content) != conf.head
    else
      false
    end
  end

  def update(conf) do
    if update?(conf) do
      with {:ok, content} <- File.read(conf.path),
	   {:ok, stat} <- File.stat(conf.path),
	     chksum = :crypto.hash(:sha, content),
	do: %Conf{path: conf.path,
		  head: chksum,
		  versions: Map.put(conf.versions, chksum,
		    %Ver{content: content,
			 parent: conf.head,
			 timestamp: stat.mtime})}
    end
  end
end

defmodule Conf.Monitor do
  use GenServer

  # Client

  def start_link(filepath) do
    GenServer.start_link(__MODULE__, Conf.new(filepath))
  end

  def status(pid) do
    GenServer.call(pid, :status)
  end

  def update(pid) do
    GenServer.cast(pid, :update)
  end

  # Server

  def handle_call(:status, _from, conf) do
    {:reply, conf, conf}
  end

  def handle_cast(:update, conf) do
    {:noreply, Conf.update(conf)}
  end
end

