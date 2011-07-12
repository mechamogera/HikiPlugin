def name_link(page_name, sec_str, link_name = nil)
  data = @db.load(page_name)
  title = nil
  unless data
    page_info = @db.page_info.find do |item| item.to_a[0][1][:title] == page_name end
    return "name_link error : can't find page [#{page_name}]" unless page_info
    title = page_name
    page_name = page_info.to_a[0][0]
    data = @db.load(page_name)
  end

  unless link_name
    unless title
      page_info = @db.page_info.find do |item| item[page_name] end
      title = page_info[page_name][:title]
    end
    link_str = "#{title}##{sec_str.unescapeHTML}"
  else
    link_str = link_name
  end

  count = 0
  data.each_line do |line|
    next unless line =~ /^!+\s*(.+)/
    target = $1.to_s
    if target == sec_str.unescapeHTML
      return "<a href=\"#{hiki_url(page_name)}#l#{count}\">#{link_str.escapeHTML}</a>"
    end
    count += 1
  end

  link_str = title unless link_name
  return "<a href=\"#{hiki_url(page_name)}\">#{link_str.escapeHTML}</a>"
end

def cname_link(sec_str, link_name = nil)
  name_link(@page, sec_str, link_name)
end

