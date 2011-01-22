module Joint
  class IO
    attr_accessor :name, :content, :type, :size

    def initialize(attrs={})
      attrs.each { |key, value| send("#{key}=", value) }
      @type ||= 'plain/text'
      @size ||= @content.size unless @content.nil?
    end

    alias path name
    alias read content
  end
end