module ApplicationHelper
  def brand_destination_path
    current_user ? dashboard_path : root_path
  end

  def status_label(status)
    { "draft" => "Taslak", "pending" => "İmza bekliyor", "signed" => "İmzalandı", "expired" => "Süresi doldu" }.fetch(status)
  end

  def status_badge(document)
    tag.span(status_label(document.status), class: "badge badge-#{document.status}")
  end

  def display_time(time)
    time ? time.in_time_zone.strftime("%d.%m.%Y · %H:%M") : "Belirlenmedi"
  end

  def sf_icon(name, css: "h-5 w-5")
    paths = {
      "grid" => "M3 3h7v7H3z M14 3h7v7h-7z M3 14h7v7H3z M14 14h7v7h-7z",
      "file" => "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z M14 2v6h6 M8 13h8 M8 17h5",
      "plus" => "M12 5v14 M5 12h14",
      "arrow" => "M5 12h14 M13 6l6 6-6 6",
      "check" => "M5 12l4 4L19 6",
      "clock" => "M12 8v4l3 2 M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0",
      "pen" => "M16 3l5 5 M3 21l5-1L21 7a2 2 0 0 0-5-5L3 15z",
      "shield" => "M12 3l9 4v5c0 5-9 10-9 10S3 17 3 12V7z M8 12l3 3 5-6"
    }
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.7,
      "stroke-linecap": "round", "stroke-linejoin": "round", class: css, "aria-hidden": true) do
      tag.path(d: paths.fetch(name))
    end
  end
end
