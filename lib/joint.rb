require 'set'
require 'mime/types'
require 'wand'

module Joint
  extend ActiveSupport::Concern

  included do
    class_attribute :attachment_names
    self.attachment_names = Set.new
    include attachment_accessor_module
  end

  def self.name(file)
    if file.kind_of?(StringIO)
      return ""
    end
    
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
    if file.kind_of?(StringIO)
      return "text/plain"
    end
    
    return file.type if file.is_a?(Joint::IO)
    Wand.wave(file.path, :original_filename => Joint.name(file))
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
