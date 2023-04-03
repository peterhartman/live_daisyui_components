defmodule LiveDaisyuiComponents.Form do
  @moduledoc """
  Form component helpers
  """

  use LiveDaisyuiComponents.Component

  import LiveDaisyuiComponents.Icon
  import LiveDaisyuiComponents.Input

  @doc """
  Renders a label.
  """
  attr :class, :any, default: nil
  attr :for, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label class={join_classes("label", @class)} for={@for} {@rest}>
      <span class="label-text"><%= render_slot(@inner_block) %></span>
    </label>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(autocomplete cols disabled form list max maxlength min minlength
                pattern placeholder readonly required rows size step)

  slot :inner_block

  def form_input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> add_attr_input_type()
    |> form_input()
  end

  def form_input(assigns) do
    ~H"""
    <div class="form-control w-full" phx-feedback-for={@name}>
      <.label for={@id}>
        <%= @label %>
      </.label>
      <.input
        id={@id}
        type={@type}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  defp add_attr_input_type(%{type: "checkbox", value: value} = assigns) do
    assigns
    |> assign_new(:checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", value) end)
    |> assign(:value, fn -> "true" end)
    |> move_attr_to_rest(:checked)
    |> add_default_input_assigns()
  end

  defp add_attr_input_type(%{type: "select"} = assigns) do
    assigns
    |> move_attr_to_rest(:multiple)
    |> add_default_input_assigns()
  end

  defp add_attr_input_type(assigns), do: add_default_input_assigns(assigns)

  defp add_default_input_assigns(assigns) do
    assigns
    |> assign_new(:color, fn -> assigns.errors != [] && "error" end)
    |> move_attr_to_rest(:color)
    |> assign_new(:bordered, fn -> assigns[:bordered] == nil && true end)
    |> move_attr_to_rest(:bordered)
    |> assign_new(:class, fn -> assigns[:class] == nil && "w-full" end)
    |> move_attr_to_rest(:class)
  end

  @doc """
  Generates a generic error message.
  """
  attr :show, :boolean, default: false
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-error phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  def translate_error({msg, _opts} = params) do
    if translate_function = Application.get_env(:live_daisyui_components, :translate_function) do
      translate_function.(params)
    else
      msg
    end
  end
end