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
    file.respond_to?(:original_filename) ? file.original_filename : File.basename(file.path)
  end

  def self.type(file)
    Wand.wave(file.path, :original_filename => Joint.name(file))
  end

  def self.size(file)
    File.size(file)
  end
end

require 'joint/class_methods'
require 'joint/instance_methods'
require 'joint/attachment_proxy'
