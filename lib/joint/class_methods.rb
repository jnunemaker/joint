module Joint
  module ClassMethods
    def attachment_accessor_module
      @attachment_accessor_module ||= Module.new
    end

    def attachment(name, options = {})
      options.symbolize_keys!
      name = name.to_sym

      self.attachment_names = attachment_names.dup.add(name)

      after_save     :save_attachments
      after_save     :destroy_nil_attachments
      before_destroy :destroy_all_attachments

      key :"#{name}_id",   ObjectId
      key :"#{name}_name", String
      key :"#{name}_size", Integer
      key :"#{name}_type", String

      validates_presence_of(name) if options[:required]

      attachment_accessor_module.module_eval <<-EOC
        def #{name}
          @#{name} ||= AttachmentProxy.new(self, :#{name})
        end

        def #{name}?
          !nil_attachments.include?(:#{name}) && send(:#{name}_id?)
        end

        def #{name}=(file)
          if file.nil?
            nil_attachments << :#{name}
            assigned_attachments.delete(:#{name})
          else
            send("#{name}_id=", BSON::ObjectId.new) if send("#{name}_id").nil?
            send("#{name}_name=", Joint.name(file))
            send("#{name}_size=", Joint.size(file))
            send("#{name}_type=", Joint.type(file))
            assigned_attachments[:#{name}] = file
            nil_attachments.delete(:#{name})
          end
        end
      EOC
    end
  end
end