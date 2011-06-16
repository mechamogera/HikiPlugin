def name_link(page_name, sec_str, link_name = nil)
  data = @db.load(page_name)
  title = nil
  unless data
    page_info = @db.page_info.find do |item| item.to_a[0][1][:title] == page_name end
    title = page_name
    page_name = page_info.to_a[0][0]
    data = @db.load(page_name)
  end

  unless link_name
    unless title
      page_info = @db.page_info.find do |item| item[page_name] end
      title = page_info[page_name][:title]
    end
    link_name = "#{title}##{sec_str.unescapeHTML}"
  end

  count = 0
  data.each_line do |line|
    next unless line =~ /^!+\s*(.+)/
    target = $1.to_s
    if target == sec_str.unescapeHTML
      return "<a href=\"#{hiki_url(page_name)}#l#{count}\">#{link_name.escapeHTML}</a>"
    end
    count += 1
  end

  return sec_str.escapeHTML
end

