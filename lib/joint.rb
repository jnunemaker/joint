require 'set'
require 'mime/types'
require 'wand'

module Joint
  def self.configure(model)
    model.class_inheritable_accessor :attachment_names
    model.attachment_names = Set.new
    model.send(:include, model.attachment_accessor_module)
  end

  def self.name(file)
    if file.respond_to?(:original_filename)
      file.original_filename
    else
      File.basename(file.path)
    end
  end

  def self.size(file)
    if file.respond_to?(:size)
      file.size
    else
      File.size(file)
    end
  end

  def self.type(file)
    type = file.content_type if file.respond_to?(:content_type)

    if blank?(type)
      type = Wand.wave(file.path, :original_filename => Joint.name(file))
    end

    type
  end

private
  def self.blank?(str)
    str.nil? || str !~ /\S/
  end
end

require 'joint/class_methods'
require 'joint/instance_methods'
require 'joint/attachment_proxy'
require 'joint/io'
