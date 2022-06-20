module ApplicationHelper

  # Returns the full title on a per-page basis.
  def full_title(page_title)
    base_title = "LDC UA"
    if page_title.nil? or (page_title.class == String and page_title.empty?)
      base_title
    else
      "#{base_title} | #{page_title}".gsub("\n","")
    end
  end

end
