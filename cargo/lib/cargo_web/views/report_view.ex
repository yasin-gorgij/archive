defmodule CargoWeb.ReportView do
  use CargoWeb, :view

  def convert_role(role) do
    case role do
      "admin" -> "مدیر سیستم"
      "user" -> "کاربر"
    end
  end

  def convert_is_blocked(is_blocked) do
    case is_blocked do
      true -> "مسدود است"
      false -> "مسدود نیست"
    end
  end

  def convert_confirmed_at(confirmed_at) do
    case confirmed_at do
      nil -> "تایید نشده"
      _ -> confirmed_at
    end
  end
end
