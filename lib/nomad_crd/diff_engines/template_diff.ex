defmodule NomadCrd.DiffEngines.TemplateDiff do
  def extract_update_patch(deployed, template) when is_list(deployed) do
    {_, diff} =
      Enum.reduce(
        deployed,
        {template, []},
        fn entry, {[tpl_entry | tail], diff_list} ->
          diff = extract_update_patch(entry, tpl_entry)
          {tail, [diff | diff_list]}
        end
      )

    Enum.reverse(diff)
  end

  def extract_update_patch(deployed, template) do
    MapDiff.diff(deployed, template)
    |> handle_diff()
  end

  def handle_diff(%{value: diff}) do
    Enum.filter(diff, fn
      {_, %{changed: :equal}} -> false
      {_, %{added: {:var, _}}} -> false
      {_, %{changed: :primitive_change}} -> true
      {_, %{changed: :map_change}} -> true
    end)
    |> Enum.map(fn {key, %{added: added, removed: removed}} ->
      update_patch = extract_update_patch(removed, added)
      # TODO: Cleanup Empty Lists ( [%{},%{},...])
      {key, update_patch}
    end)
    |> Map.new()
  end

  def handle_diff(%{added: added, changed: :primitive_change}) do
    added
  end
end
