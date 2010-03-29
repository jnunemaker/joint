require 'helper'

class Foo
  include MongoMapper::Document
  plugin Joint

  attachment :image
  attachment :pdf
end

class JointTest < Test::Unit::TestCase
  def setup
    MongoMapper.database.collections.each(&:remove)
    dir             = File.dirname(__FILE__) + '/fixtures'
    @pdf            = File.open("#{dir}/unixref.pdf",  'r')
    @image          = File.open("#{dir}/mr_t.jpg", 'r')
    @pdf_contents   = File.read("#{dir}/unixref.pdf")
    @image_contents = File.read("#{dir}/mr_t.jpg")
    @grid           = Mongo::Grid.new(MongoMapper.database)
  end

  def teardown
    @pdf.close
    @image.close
  end

  context "Assigning attachments to document" do
    setup do
      @doc = Foo.create(:image => @image, :pdf => @pdf)
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
  end

  context "Retrieving attachment that does not exist" do
    setup do
      @doc = Foo.create
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
      @doc = Foo.create(:image => @image)
    end

    should "remove files from grid fs as well" do
      assert_difference "MongoMapper.database['fs.files'].find().count", -1 do
        @doc.destroy
      end
    end
  end

  context "Assigning file name" do
    should "default to path" do
      Foo.create(:image => @image).image.name.should == 'mr_t.jpg'
    end

    should "use original_filename if available" do
      begin
        file = Tempfile.new('testing.txt')
        def file.original_filename
          'testing.txt'
        end
        doc = Foo.create(:image => file)
        assert_equal 'testing.txt', doc.image_name
      ensure
        file.close
      end
    end
  end
end