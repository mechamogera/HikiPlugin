require 'time'

def work_form_start
  <<-FORM
<form style="display: inline" action="#{@conf.cgi_name}" method="post">
<span>
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

def work_record(title = "record")
  <<-FORM
<input type="submit" name="record" value="#{title}">
  FORM
end

def work_free_text_start
end

def work_free_text_end
end

module WorkPlugin
  class Base
    class << self
      attr_reader :method_name
      attr_reader :pattern
    end

    def initialize(*args)
      @uniq_id = args[0]
    end

    def already_input?(lines)
      pattern = /(#{self.class.pattern})?\{\{#{self.class.method_name}\("#{Regexp.escape(@uniq_id.unescapeHTML)}".*\}\}/   
      lines.each do |line|
        if line =~ pattern
          return true if $1
          break
        end  
      end

      return false
    end

    def convert_line(line, value)
      pattern = /(#{self.class.pattern})?\{\{#{self.class.method_name}\("#{Regexp.escape(@uniq_id)}"(.*)\}\}/
      if line =~ pattern
        return line.sub(pattern, "#{value}{{#{self.class.method_name}(\"#{@uniq_id}\"#{$2}}}")
      else
        return line
      end
    end
  end

  class OkNg < Base
    @method_name = "work_okng"
    @pattern = "OK|NG"

    def self.uniq_id(param)
      return nil unless param =~ /^okng_/
      return param.sub(/^okng_/, "")
    end

    def form
      <<-FORM
<input type="radio" name="okng_#{@uniq_id}" value="OK" />OK 
<input type="radio" name="okng_#{@uniq_id}" value="NG" />NG
      FORM
    end

    def get_value(params)
      return params["okng_#{@uniq_id}"][0]
    end
  end

  class TimeSpan < Base
    @method_name = "work_timespan"
    @pattern = '\d+min\(\d{2}:\d{2}-\d{2}:\d{2}\)'

    def self.uniq_id(param)
      return nil unless param =~ /^timespan_starttime_/
      return param.sub(/^timespan_starttime_/, "")
    end

    def form
      <<-FORM
<input type="text" name="timespan_starttime_#{@uniq_id}" value="HH:MM" size="5">
- <input type="text" name="timespan_endtime_#{@uniq_id}" value="HH:MM" size="5">
      FORM
    end

    def get_value(params)
      start_time = params["timespan_starttime_#{@uniq_id}"][0]
      end_time = params["timespan_endtime_#{@uniq_id}"][0]
      return nil unless start_time =~ /^\d{2}:\d{2}$/
      return nil unless end_time =~ /^\d{2}:\d{2}$/
      span = ::Time.parse(end_time) - ::Time.parse(start_time)
      return "#{span.to_i/60}min(#{start_time}-#{end_time})"
    end
  end

  class Time < Base
    @method_name = "work_time"
    @pattern = '\d{2}:\d{2}'

    def self.uniq_id(param)
      return nil unless param =~ /^time_/
      return param.sub(/^time_/, "")
    end

    def form
      <<-FORM
<input type="text" name="time_#{@uniq_id}" value="HH:MM" size="5">
      FORM
    end

    def get_value(params)
      value = params["time_#{@uniq_id}"][0]
      return nil unless value =~ /^#{self.class.pattern}$/
      return value
    end
  end

  class FreeText < Base
    @method_name = "work_free_text"
    @pattern = '\{\{work_free_text_start\}\}.+?\{\{work_free_text_end\}\}'

    def initialize(*args)
      super(args[0])
      @options = {:default => "", :size => 10}
      args[1..-1].each do |x|
        case x
        when String
          @options[:default] = x
        when Integer
          @options[:size] = x
        end
      end
    end

    def self.uniq_id(param)
      return nil unless param =~ /^free_text_value_/
      return param.sub(/^free_text_value_/, "")
    end

    def form
      <<-FORM
<input type="text" name="free_text_value_#{@uniq_id}" value="#{@options[:default]}" size="#{@options[:size]}">
<input type="hidden" name="free_text_default_#{@uniq_id}" value="#{@options[:default]}">
      FORM
    end

    def get_value(params)
      value = params["free_text_value_#{@uniq_id}"][0]
      default = params["free_text_default_#{@uniq_id}"][0] || ""
      return nil if value == default
      return "{{work_free_text_start}}#{value}{{work_free_text_end}}"
    end
  end

  List = [OkNg, TimeSpan, Time, FreeText]
end

class << self
  WorkPlugin::List.each do |klass|
    define_method(klass.method_name.to_sym) do |*args|
      obj = klass.new(*args)
      return '' if obj.already_input?(@db.load(@page))

      return obj.form
    end
  end
end

def work_post
  targets = []
  @cgi.params.each do |param, value|
    WorkPlugin::List.each do |klass|
      next unless uniq_id = klass.uniq_id(param)
      obj = klass.new(uniq_id)
      next unless value = obj.get_value(@cgi.params)
      targets << {:obj => obj, :value => value}
    end
  end

  return '' if targets.empty?

  content = ''
  lines = @db.load(@page)
  lines.each do |line|
    targets.each do |target|
      line = target[:obj].convert_line(line, target[:value])
    end
    content << line
  end

  save(@page, content, @db.md5hex(@page))
end

methods = []
WorkPlugin::List.each do |klass|
  methods << klass.method_name.to_sym
end

export_plugin_methods(:work_form_start, 
                      :work_form_end,
                      :work_record, 
                      :work_post,
                      :work_free_text_start,
                      :work_free_text_end,
                      *methods)
