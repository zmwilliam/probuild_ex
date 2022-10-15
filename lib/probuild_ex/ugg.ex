defmodule ProbuildEx.UGG do
  @moduledoc false

  @url "https://stats2.u.gg/pro/pro-list.json"

  def pro_list do
    %{body: body} = Tesla.get!(@url)
    Jason.decode!(body)
  end
end
