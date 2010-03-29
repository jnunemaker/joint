require 'helper'

class Asset
  include MongoMapper::Document
  plugin Joint

  key :title, String
  attachment :image
  attachment :pdf
end

class JointTest < Test::Unit::TestCase
  def setup
    MongoMapper.database.collections.each(&:remove)

    dir                = File.dirname(__FILE__) + '/fixtures'
    @pdf               = File.open("#{dir}/unixref.pdf",  'r')
    @image             = File.open("#{dir}/mr_t.jpg", 'r')
    @pdf_contents      = File.read("#{dir}/unixref.pdf")
    @image_contents    = File.read("#{dir}/mr_t.jpg")
    @grid              = Mongo::Grid.new(MongoMapper.database)
    @gridfs_collection = MongoMapper.database['fs.files']
  end

  def teardown
    @pdf.close
    @image.close
  end

  context "Using Joint plugin" do
    should "add each attachment to attachment_names" do
      Asset.attachment_names.should == [:image, :pdf]
    end

    should "add keys for each attachment" do
      [:image, :pdf].each do |attachment|
        [:id, :name, :type, :size].each do |key|
          Asset.keys.include?("#{attachment}_#{key}")
        end
      end
    end
  end

  context "Assigning attachments to document" do
    setup do
      @doc = Asset.create(:image => @image, :pdf => @pdf)
      @doc.reload
    end

    should "assign GridFS content_type" do
      @grid.get(@doc.image_id).content_type.should == 'image/jpeg'
      @grid.get(@doc.pdf_id).content_type.should == 'application/pdf'
    end

    should "assign joint keys" do
      @doc.image_size.should  == 13661
      @doc.pdf_size.should    == 68926

      @doc.image_type.should  == "image/jpeg"
      @doc.pdf_type.should    == "application/pdf"

      @doc.image_id.should_not be_nil
      @doc.pdf_id.should_not be_nil

      @doc.image_id.should be_instance_of(Mongo::ObjectID)
      @doc.pdf_id.should be_instance_of(Mongo::ObjectID)
    end

    should "allow accessing keys through attachment proxy" do
      @doc.image.size.should  == 13661
      @doc.pdf.size.should    == 68926

      @doc.image.type.should  == "image/jpeg"
      @doc.pdf.type.should    == "application/pdf"

      @doc.image.id.should_not be_nil
      @doc.pdf.id.should_not be_nil

      @doc.image.id.should be_instance_of(Mongo::ObjectID)
      @doc.pdf.id.should be_instance_of(Mongo::ObjectID)
    end

    should "proxy unknown methods to GridIO object" do
      @doc.image.files_id.should      == @doc.image_id
      @doc.image.content_type.should  == 'image/jpeg'
      @doc.image.filename.should      == 'mr_t.jpg'
      @doc.image.file_length.should   == 13661
    end

    should "assign file name from path if original file name not available" do
      @doc.image_name.should  == 'mr_t.jpg'
      @doc.pdf_name.should    == 'unixref.pdf'
    end

    should "save attachment contents correctly" do
      @doc.pdf.read.should    == @pdf_contents
      @doc.image.read.should  == @image_contents
    end

    should "know that attachment exists" do
      @doc.image?.should be(true)
      @doc.pdf?.should be(true)
    end

    should "clear assigned attachments so they don't get uploaded twice" do
      Mongo::Grid.any_instance.expects(:put).never
      @doc.save
    end
  end

  context "Updating document but not attachments" do
    setup do
      @doc = Asset.create(:image => @image)
      @doc.update_attributes(:title => 'Updated')
      @doc.reload
    end

    should "not affect attachment" do
      @doc.image.read.should == @image_contents
    end

    should "update document attributes" do
      @doc.title.should == 'Updated'
    end
  end

  context "Assigning file with where file pointer is not at beginning" do
    setup do
      @image.read
      @doc = Asset.create(:image => @image)
      @doc.reload
    end

    should "rewind and correctly store contents" do
      @doc.image.read.should == @image_contents
    end
  end

  context "Setting attachment to nil" do
    setup do
      @doc = Asset.create(:image => @image)
    end

    should "delete attachment after save" do
      assert_no_difference '@gridfs_collection.find().count' do
        @doc.image = nil
      end

      assert_difference '@gridfs_collection.find().count', -1 do
        @doc.save
      end
    end
    
    should "clear nil attachments after save and not attempt to delete again" do
      @doc.image = nil
      @doc.save
      Mongo::Grid.any_instance.expects(:delete).never
      @doc.save
    end
  end

  context "Retrieving attachment that does not exist" do
    setup do
      @doc = Asset.create
    end

    should "know that the attachment is not present" do
      @doc.image?.should be(false)
    end

    should "raise Mongo::GridError" do
      assert_raises(Mongo::GridError) { @doc.image.read }
    end
  end

  context "Destroying a document" do
    setup do
      @doc = Asset.create(:image => @image)
    end

    should "remove files from grid fs as well" do
      assert_difference "@gridfs_collection.find().count", -1 do
        @doc.destroy
      end
    end
  end

  context "Assigning file name" do
    should "default to path" do
      Asset.create(:image => @image).image.name.should == 'mr_t.jpg'
    end

    should "use original_filename if available" do
      begin
        file = Tempfile.new('testing.txt')
        def file.original_filename
          'testing.txt'
        end
        doc = Asset.create(:image => file)
        assert_equal 'testing.txt', doc.image_name
      ensure
        file.close
      end
    end
  end
end