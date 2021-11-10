defmodule NomadCrd.TemplateRender do
  def render(template_module, variables) do
    template = template_module.template()

    template
    |> render_struct(variables)
  end

  def render_struct(struct, variables) do
    values =
      struct
      |> Map.from_struct()
      |> Enum.map(&parse_entry(&1, variables))

    struct!(struct, values)
  end

  def render_list(list, variables) do
    list
    |> Enum.map(fn entry ->
      map_entry(entry, variables)
    end)
  end

  def parse_entry({key, value}, variables) do
    {key, map_entry(value, variables)}
  end

  defp map_entry({:var, var}, variables) when is_atom(var) do
    Map.get(variables, var)
  end

  defp map_entry({:var, fun}, variables) when is_function(fun) do
    fun.(variables)
  end

  defp map_entry(struct, variables) when is_struct(struct) do
    render_struct(struct, variables)
  end

  defp map_entry(map, variables) when is_map(map) do
    map
    |> Enum.map(&parse_entry(&1, variables))
    |> Map.new()
  end

  defp map_entry(list, variables) when is_list(list) do
    render_list(list, variables)
  end

  defp map_entry(value, _variables) when is_binary(value) or is_nil(value) or is_boolean(value) do
    value
  end
end
