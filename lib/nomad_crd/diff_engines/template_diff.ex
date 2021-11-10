defmodule NomadCrd.DiffEngines.TemplateDiff do
  def diff(deployed, template_module) do
    template = template_module.template()

    extract_update_patch(deployed, template)
  end

  def patch(source, patch) do
    patch
    |> Enum.reduce(source, &apply_patch/2)
  end

  def patch_list([], []) do
    []
  end

  def patch_list([source_h | source_t], [patch_h | patch_t]) do
    [patch(source_h, patch_h) | patch_list(source_t, patch_t)]
  end

  def apply_patch({key, value}, acc) when is_atom(value) or is_binary(value) do
    Map.put(acc, key, value)
  end

  def apply_patch({key, value}, acc) when is_list(value) do
    Map.update(acc, key, value, fn source -> patch_list(source, value) end)
  end

  def apply_patch({key, value}, acc) when is_map(value) do
    Map.update(acc, key, value, fn source -> Enum.reduce(value, source, &apply_patch/2) end)
  end

  def extract_update_patch(deployed, template) when is_list(deployed) do
    # Evaluates if list can be checked with myers
    myers_check = fn val ->
      is_binary(val) or is_integer(val) or match?({:var, _}, val) or is_atom(val)
    end

    if Enum.all?(deployed, myers_check) and Enum.all?(template, myers_check) do
      IO.inspect(deployed, label: :myer)
      myers_difference(deployed, template)
    else
      hick_hack_diff(deployed, template)
    end
  end

  def hick_hack_diff(deployed, template) when is_list(deployed) do
    {_, diff} =
      Enum.reduce(
        deployed,
        {template, []},
        fn entry, {[tpl_entry | tail], diff_list} ->
          diff = extract_update_patch(entry, tpl_entry)
          {tail, [diff | diff_list]}
        end
      )

    # Returns unchanged list as nil, since empty list could be wrongly interpreted
    if Enum.all?(diff, &(&1 == %{})) do
      nil
    else
      Enum.reverse(diff)
    end
  end

  def myers_difference(deployed, template) when is_list(deployed) do
    deployed
    |> List.myers_difference(template)
    |> IO.inspect()
    |> Enum.reject(fn {type, _} -> type in [:del] end)
    |> Enum.flat_map(fn
      {:eq, val} -> val
      {:ins, val} -> val
    end)
    |> List.flatten()
    |> Enum.map(fn
      {:var, _} -> {:no_change}
      val -> val
    end)
  end

  def extract_update_patch(deployed, template) do
    MapDiff.diff(deployed, template)
    |> handle_diff()
  end

  def handle_diff(%{value: diff}) when is_map(diff) do
    Enum.filter(diff, fn
      # Empty Lists will be nulled by nomad
      {_, %{added: [], changed: :primitive_change, removed: nil}} -> false
      # We don't care about equal values
      {_, %{changed: :equal}} -> false
      # Ignore Template values
      {_, %{added: {:var, _}}} -> false
      # Ignore nil Values, as they are set by the Job Struct
      {_, %{added: nil}} -> false
      # Those are the interessing values:
      {_, %{changed: :primitive_change}} -> true
      {_, %{changed: :map_change}} -> true
    end)
    |> Enum.reduce([], fn {key, %{removed: removed, added: added}}, acc ->
      update_patch = extract_update_patch(removed, added)

      case update_patch do
        nil -> acc
        _ -> [{key, update_patch} | acc]
      end
    end)
    |> Map.new()
  end

  def handle_diff(%{changed: :equal}) do
    {:no_change}
  end

  def handle_diff(%{added: added, changed: :primitive_change}) do
    added
  end
end
