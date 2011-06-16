def okng(uniq_id)
  return '' if @conf.use_session && !@session_id

  lines = @db.load( @page )
  pattern = /(OK|NG)?\{\{okng\("#{uniq_id.unescapeHTML}"(.*)\}\}/

  lines.each do |line|
    if line =~ pattern
      return '' if $1
      break
    end
  end

  <<EOS
<form style="display: inline" action="#{@conf.cgi_name}" method="post">
  <span>
    <input type="submit" name="OK" value="OK">
    <input type="submit" name="NG" value="NG">
    <input type="hidden" name="c" value="plugin">
    <input type="hidden" name="p" value="#{@page.escapeHTML}">
    <input type="hidden" name="plugin" value="okng_post">
    <input type="hidden" name="session_id" value="#{@session_id}">
    <input type="hidden" name="uniq_id" value="#{uniq_id}">
  </span>
</form>
EOS
end

def okng_post
  return '' if @conf.use_session && @session_id != @cgi['session_id']

  params     = @cgi.params
  uniq_id    = params['uniq_id'][0]
  okng       = params['OK'][0] || params['NG'][0]

  lines = @db.load( @page )
  md5hex = @db.md5hex( @page )

  flag = false
  pattern = /(OK|NG)?\{\{okng\("#{uniq_id}"(.*)\}\}/

  content = ''
  lines.each do |line|
    if line =~ pattern && !flag
      content << line.sub(pattern,"#{okng}{{okng(\"#{uniq_id}\"#{$2}}}")
      flag = true
    else
      content << line
    end
  end

  save( @page, content, md5hex ) if flag
end

def okng_id_check
  lines = @db.load(@page)
  pattern = /\{\{okng\("([^"]+)"/
  uniq_ids = Hash.new(0)
  lines.each do |line|
    while line =~ pattern
      uniq_ids[$1.to_s] += 1
      line = $'.to_s
    end
  end
  inv_ids = uniq_ids.find_all do |item| item[1] > 1 end

  return '' if inv_ids.empty?
  inv_str = inv_ids.map { |x| x[0] }.join(",")
  return "okng's uniq_ids [#{inv_str}] repeated"
end

