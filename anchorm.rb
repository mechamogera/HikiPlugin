def anchorm(anchor_name)
  return "<a name=\"#{anchor_name}\"> </a>"
end

def anchorm_link(page_name, anchor_name, link_name = nil)
	page_info = @db.page_info.find do |item| 
		(item.to_a[0][0] == page_name) || (item.to_a[0][1][:title] == page_name)
  end
  page = page_info.to_a[0][0]
	
	unless link_name 
		title = page_info.to_a[0][1][:title]
    link_name = "#{title}##{anchor_name}" 
  end

	return "<a href=\"#{hiki_url(page)}##{anchor_name}\">#{link_name}</a>"
end

