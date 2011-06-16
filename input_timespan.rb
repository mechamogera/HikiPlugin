# $Id: input_timespen.rb,v 0.80 2011-06-12 06:46:43 fdiary Exp $
# Copyright (C) 2011 mechamogera

require 'time'

def input_timespan(uniq_id)
  return '' if @conf.use_session && !@session_id

  pattern = /(\d+min\(\d{2}:\d{2}-\d{2}:\d{2}\))?\{\{input_timespan\("#{uniq_id.unescapeHTML}".*\}\}/   
  lines = @db.load( @page )
  lines.each do |line|
    if line =~ pattern
      return '' if $1
      break
    end
  end

  <<EOS
<form style="display: inline" action="#{@conf.cgi_name}" method="post">
  <span>
    <input type="text" name="start_time" value="HH:MM" size="5">
    - <input type="text" name="end_time" value="HH:MM" size="5">
    <input type="submit" name="record" value="record">
    <input type="hidden" name="c" value="plugin">
    <input type="hidden" name="p" value="#{@page.escapeHTML}">
    <input type="hidden" name="plugin" value="input_timespan_post">
    <input type="hidden" name="session_id" value="#{@session_id}">
    <input type="hidden" name="uniq_id" value="#{uniq_id}">
  </span>
</form>
EOS
end

def input_timespan_post
  return '' if @conf.use_session && @session_id != @cgi['session_id']

  params     = @cgi.params
  uniq_id    = params['uniq_id'][0]
  start_time = params['start_time'][0]
  end_time   = params['end_time'][0]

  return '' unless start_time =~ /^\d{2}:\d{2}$/
  return '' unless end_time =~ /^\d{2}:\d{2}$/

  lines = @db.load( @page )
  md5hex = @db.md5hex( @page )

  flag = false
  pattern = /(\d+min\(\d{2}:\d{2}-\d{2}\d{2}\))?\{\{input_timespan\("#{uniq_id}".*\}\}/   

  span = Time.parse(end_time) - Time.parse(start_time)
  time = "#{span.to_i/60}min(#{start_time}-#{end_time})"

  content = ''
  lines.each do |line|
    if line =~ pattern && !flag
      content << line.sub(pattern, "#{time}{{input_timespan(\"#{uniq_id}\"#{$2}}}")
      flag = true
    else
      content << line
    end
  end

  save( @page, content, md5hex ) if flag
end

def input_timespan_id_check
  lines = @db.load(@page)
  pattern = /\{\{input_timespan\("([^"]+)"/
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
  return "input_timespan's uniq_ids [#{inv_str}] repeated"
end

