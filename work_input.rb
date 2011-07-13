def work_form_start
  <<-FORM
<form style="display: inline" action="#{@conf.cgi_name}" method="post">
<span>
<input type="submit" name="record" value="record">
<input type="hidden" name="c" value="plugin">
<input type="hidden" name="p" value="#{@page.escapeHTML}">
<input type="hidden" name="plugin" value="work_post">
<input type="hidden" name="session_id" value="#{@session_id}">
  FORM
end

def work_form_end
  <<-FORM
</span>
</form>
  FORM
end

def work_okng(uniq_id)
  return '' if already_input?(__method__, uniq_id, "OK|NG")

  <<-FORM
<input type="radio" name="okng_#{uniq_id}" value="OK" />OK 
<input type="radio" name="okng_#{uniq_id}" value="NG" />NG
  FORM
end

def work_timespan(uniq_id)
  return '' if already_input?(__method__, uniq_id, '\d+min\(\d{2}:\d{2}-\d{2}:\d{2}\)')

  <<-FORM
<input type="text" name="timespan_starttime_#{uniq_id}" value="HH:MM" size="5">
- <input type="text" name="timespan_endtime_#{uniq_id}" value="HH:MM" size="5">
  FORM  
end

def work_post
  targets = []
  @cgi.params.each do |param, value| 
    if param =~ /^okng_/
      targets << {:method_name => "work_okng", :uniq_id => param.sub(/^okng_/, ""), :value => value[0]}
    end
  end

  content = ''
  lines = @db.load(@page)
  lines.each do |line|
    targets.each do |target|
      line = check_line(line, target[:method_name], target[:uniq_id], "OK|NG", target[:value])
    end
    content << line
  end

  save(@page, content, @db.md5hex(@page))
end

def check_line(line, method_name, uniq_id, pattern, value)
  pattern = /(#{pattern})?\{\{#{method_name}\("#{Regexp.escape(uniq_id)}"(.*)\}\}/
  if line =~ pattern
    return line.sub(pattern, "#{value}{{#{method_name}(\"#{uniq_id}\"#{$2}}}")
  else
    return line
  end
end

def already_input?(method_name, uniq_id, pattern)
  pattern = /(#{pattern})?\{\{#{method_name}\("#{Regexp.escape(uniq_id.unescapeHTML)}".*\}\}/   
  lines = @db.load( @page )
  lines.each do |line|
    if line =~ pattern
      return true if $1
      break
    end  
  end

  return false
end
