require 'helper'

describe "JointTest" do
  include JointTestHelpers

  before do
    @file   = open_file('unixref.pdf')
    @image  = open_file('mr_t.jpg')
    @image2 = open_file('harmony.png')
    @test1  = open_file('test1.txt')
    @test2  = open_file('test2.txt')
  end

  after do
    all_files.each { |file| file.close }
  end

  describe "Using Joint plugin" do
    it "add each attachment to attachment_names" do
      Asset.attachment_names.must_equal Set.new([:image, :file])
      EmbeddedAsset.attachment_names.must_equal Set.new([:image, :file])
    end

    it "add keys for each attachment" do
      key_names.each do |key|
        Asset.keys.must_include "image_#{key}"
        Asset.keys.must_include "file_#{key}"
        EmbeddedAsset.keys.must_include "image_#{key}"
        EmbeddedAsset.keys.must_include "file_#{key}"
      end
    end

    it "add memoized accessors module" do
      Asset.attachment_accessor_module.must_be_instance_of(Module)
      EmbeddedAsset.attachment_accessor_module.must_be_instance_of(Module)
    end

    describe "with inheritance" do
      it "add attachment to attachment_names" do
        BaseModel.attachment_names.must_equal Set.new([:file])
      end

      it "inherit attachments from superclass, but not share other inherited class attachments" do
        Image.attachment_names.must_equal Set.new([:file, :image])
        Video.attachment_names.must_equal Set.new([:file, :video])
      end

      it "add inherit keys from superclass" do
        key_names.each do |key|
          BaseModel.keys.must_include("file_#{key}")
          Image.keys.must_include("file_#{key}")
          Image.keys.must_include("image_#{key}")
          Video.keys.must_include("file_#{key}")
          Video.keys.must_include("video_#{key}")
        end
      end
    end
  end

  describe "Assigning new attachments to document" do
    before do
      @doc = Asset.create(:image => @image, :file => @file)
      rewind_files
    end
    let(:subject) { @doc }

    it "assign GridFS content_type" do
      grid.get(subject.image_id).content_type.must_equal 'image/jpeg'
      grid.get(subject.file_id).content_type.must_equal 'application/pdf'
    end

    it "assign joint keys" do
      subject.image_size.must_equal 13661
      subject.file_size.must_equal 68926

      subject.image_type.must_equal "image/jpeg"
      subject.file_type.must_equal "application/pdf"

      subject.image_id.wont_be_nil
      subject.file_id.wont_be_nil

      subject.image_id.must_be_instance_of(BSON::ObjectId)
      subject.file_id.must_be_instance_of(BSON::ObjectId)
    end

    it "allow accessing keys through attachment proxy" do
      subject.image.size.must_equal 13661
      subject.file.size.must_equal 68926

      subject.image.type.must_equal "image/jpeg"
      subject.file.type.must_equal "application/pdf"

      subject.image.id.wont_be_nil
      subject.file.id.wont_be_nil

      subject.image.id.must_be_instance_of(BSON::ObjectId)
      subject.file.id.must_be_instance_of(BSON::ObjectId)
    end

    it "proxy unknown methods to GridIO object" do
      subject.image.files_id.must_equal subject.image_id
      subject.image.content_type.must_equal 'image/jpeg'
      subject.image.filename.must_equal 'mr_t.jpg'
      subject.image.file_length.must_equal 13661
    end

    it "assign file name from path if original file name not available" do
      subject.image_name.must_equal 'mr_t.jpg'
      subject.file_name.must_equal 'unixref.pdf'
    end

    it "save attachment contents correctly" do
      subject.file.read.must_equal @file.read
      subject.image.read.must_equal @image.read
    end

    it "know that attachment exists" do
      subject.image?.must_equal(true)
      subject.file?.must_equal(true)
    end

    it "respond with false when asked if the attachment is blank?" do
      subject.image.blank?.must_equal(false)
      subject.file.blank?.must_equal(false)
    end

    it "clear assigned attachments so they don't get uploaded twice" do
      Mongo::Grid.any_instance.expects(:put).never
      subject.save
    end
  end

  describe "Assigning new attachments to embedded document" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:image => @image, :file => @file)
      @asset.save!
      rewind_files
    end
    let(:subject) { @doc }

    it "assign GridFS content_type" do
      grid.get(subject.image_id).content_type.must_equal 'image/jpeg'
      grid.get(subject.file_id).content_type.must_equal 'application/pdf'
    end

    it "assign joint keys" do
      subject.image_size.must_equal 13661
      subject.file_size.must_equal 68926

      subject.image_type.must_equal "image/jpeg"
      subject.file_type.must_equal "application/pdf"

      subject.image_id.wont_be_nil
      subject.file_id.wont_be_nil

      subject.image_id.must_be_instance_of(BSON::ObjectId)
      subject.file_id.must_be_instance_of(BSON::ObjectId)
    end

    it "allow accessing keys through attachment proxy" do
      subject.image.size.must_equal 13661
      subject.file.size.must_equal 68926

      subject.image.type.must_equal "image/jpeg"
      subject.file.type.must_equal "application/pdf"

      subject.image.id.wont_be_nil
      subject.file.id.wont_be_nil

      subject.image.id.must_be_instance_of(BSON::ObjectId)
      subject.file.id.must_be_instance_of(BSON::ObjectId)
    end

    it "proxy unknown methods to GridIO object" do
      subject.image.files_id.must_equal subject.image_id
      subject.image.content_type.must_equal 'image/jpeg'
      subject.image.filename.must_equal 'mr_t.jpg'
      subject.image.file_length.must_equal 13661
    end

    it "assign file name from path if original file name not available" do
      subject.image_name.must_equal 'mr_t.jpg'
      subject.file_name.must_equal 'unixref.pdf'
    end

    it "save attachment contents correctly" do
      subject.file.read.must_equal @file.read
      subject.image.read.must_equal @image.read
    end

    it "know that attachment exists" do
      subject.image?.must_equal(true)
      subject.file?.must_equal(true)
    end

    it "respond with false when asked if the attachment is blank?" do
      subject.image.blank?.must_equal(false)
      subject.file.blank?.must_equal(false)
    end

    it "clear assigned attachments so they don't get uploaded twice" do
      Mongo::Grid.any_instance.expects(:put).never
      subject.save
    end
  end

  describe "Updating existing attachment" do
    before do
      @doc = Asset.create(:file => @test1)
      assert_no_grid_difference do
        @doc.file = @test2
        @doc.save!
      end
      rewind_files
    end
    let(:subject) { @doc }

    it "not change attachment id" do
      subject.file_id_changed?.must_equal(false)
    end

    it "update keys" do
      subject.file_name.must_equal 'test2.txt'
      subject.file_type.must_equal "text/plain"
      subject.file_size.must_equal 5
    end

    it "update GridFS" do
      grid.get(subject.file_id).filename.must_equal 'test2.txt'
      grid.get(subject.file_id).content_type.must_equal 'text/plain'
      grid.get(subject.file_id).file_length.must_equal 5
      grid.get(subject.file_id).read.must_equal @test2.read
    end
  end

  describe "Updating existing attachment in embedded document" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:file => @test1)
      @asset.save!
      assert_no_grid_difference do
        @doc.file = @test2
        @doc.save!
      end
      rewind_files
    end
    let(:subject) { @doc }

    it "update keys" do
      subject.file_name.must_equal 'test2.txt'
      subject.file_type.must_equal "text/plain"
      subject.file_size.must_equal 5
    end

    it "update GridFS" do
      grid.get(subject.file_id).filename.must_equal 'test2.txt'
      grid.get(subject.file_id).content_type.must_equal 'text/plain'
      grid.get(subject.file_id).file_length.must_equal 5
      grid.get(subject.file_id).read.must_equal @test2.read
    end
  end

  describe "Updating document but not attachments" do
    before do
      @doc = Asset.create(:image => @image)
      @doc.update_attributes(:title => 'Updated')
      @doc.reload
      rewind_files
    end
    let(:subject) { @doc }

    it "not affect attachment" do
      subject.image.read.must_equal @image.read
    end

    it "update document attributes" do
      subject.title.must_equal 'Updated'
    end
  end

  describe "Updating embedded document but not attachments" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:image => @image)
      @doc.update_attributes(:title => 'Updated')
      @asset.reload
      @doc = @asset.embedded_assets.first
      rewind_files
    end
    let(:subject) { @doc }

    it "not affect attachment" do
      subject.image.read.must_equal @image.read
    end

    it "update document attributes" do
      subject.title.must_equal 'Updated'
    end
  end

  describe "Assigning file where file pointer is not at beginning" do
    before do
      @image.read
      @doc = Asset.create(:image => @image)
      @doc.reload
      rewind_files
    end
    let(:subject) { @doc }

    it "rewind and correctly store contents" do
      subject.image.read.must_equal @image.read
    end
  end

  describe "Setting attachment to nil" do
    before do
      @doc = Asset.create(:image => @image)
      rewind_files
    end
    let(:subject) { @doc }

    it "delete attachment after save" do
      assert_no_grid_difference   { subject.image = nil }
      assert_grid_difference(-1)  { subject.save }
    end

    it "know that the attachment has been nullified" do
      subject.image = nil
      subject.image?.must_equal(false)
    end

    it "respond with true when asked if the attachment is nil?" do
      subject.image = nil
      subject.image.nil?.must_equal(true)
    end

    it "respond with true when asked if the attachment is blank?" do
      subject.image = nil
      subject.image.blank?.must_equal(true)
    end

    it "clear nil attachments after save and not attempt to delete again" do
      Mongo::Grid.any_instance.expects(:delete).once
      subject.image = nil
      subject.save
      Mongo::Grid.any_instance.expects(:delete).never
      subject.save
    end

    it "clear id, name, type, size" do
      subject.image = nil
      subject.save
      assert_nil subject.image_id
      assert_nil subject.image_name
      assert_nil subject.image_type
      assert_nil subject.image_size
      subject.reload
      assert_nil subject.image_id
      assert_nil subject.image_name
      assert_nil subject.image_type
      assert_nil subject.image_size
    end
  end

  describe "Setting attachment to nil on embedded document" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:image => @image)
      @asset.save!
      rewind_files
    end
    let(:subject) { @doc }

    it "delete attachment after save" do
      assert_no_grid_difference   { subject.image = nil }
      assert_grid_difference(-1)  { subject.save }
    end

    it "know that the attachment has been nullified" do
      subject.image = nil
      subject.image?.must_equal(false)
    end

    it "respond with true when asked if the attachment is nil?" do
      subject.image = nil
      subject.image.nil?.must_equal(true)
    end

    it "respond with true when asked if the attachment is blank?" do
      subject.image = nil
      subject.image.blank?.must_equal(true)
    end

    it "clear nil attachments after save and not attempt to delete again" do
      Mongo::Grid.any_instance.expects(:delete).once
      subject.image = nil
      subject.save
      Mongo::Grid.any_instance.expects(:delete).never
      subject.save
    end

    it "clear id, name, type, size" do
      subject.image = nil
      subject.save
      assert_nil subject.image_id
      assert_nil subject.image_name
      assert_nil subject.image_type
      assert_nil subject.image_size
      s = subject._root_document.reload.embedded_assets.first
      assert_nil s.image_id
      assert_nil s.image_name
      assert_nil s.image_type
      assert_nil s.image_size
    end
  end

  describe "Retrieving attachment that does not exist" do
    before do
      @doc = Asset.create
      rewind_files
    end
    let(:subject) { @doc }

    it "know that the attachment is not present" do
      subject.image?.must_equal(false)
    end

    it "respond with true when asked if the attachment is nil?" do
      subject.image.nil?.must_equal(true)
    end

    it "raise Mongo::GridFileNotFound" do
      assert_raises(Mongo::GridFileNotFound) { subject.image.read }
    end
  end

  describe "Destroying a document" do
    before do
      @doc = Asset.create(:image => @image)
      rewind_files
    end
    let(:subject) { @doc }

    it "remove files from grid fs as well" do
      assert_grid_difference(-1) { subject.destroy }
    end
  end

  describe "Destroying an embedded document's _root_document" do
    before do
      @asset = Asset.new
      @doc = @asset.embedded_assets.build(:image => @image)
      @doc.save!
      rewind_files
    end
    let(:subject) { @doc }

    it "remove files from grid fs as well" do
      assert_grid_difference(-1) { subject._root_document.destroy }
    end
  end

#   # What about when an embedded document is removed?

  describe "Assigning file name" do
    it "default to path" do
      Asset.create(:image => @image).image.name.must_equal 'mr_t.jpg'
    end

    it "use original_filename if available" do
      def @image.original_filename
        'testing.txt'
      end
      doc = Asset.create(:image => @image)
      assert_equal 'testing.txt', doc.image_name
    end
  end

  describe "Validating attachment presence" do
    before do
      @model_class = Class.new do
        include MongoMapper::Document
        plugin Joint
        attachment :file, :required => true

        def self.name; "Foo"; end
      end
    end

    it "work" do
      model = @model_class.new
      refute model.valid?

      model.file = @file
      assert model.valid?

      model.file = nil
      refute model.valid?

      model.file = @image
      assert model.valid?
    end
  end

  describe "Assigning joint io instance" do
    before do
      io = Joint::IO.new({
        :name    => 'foo.txt',
        :type    => 'plain/text',
        :content => 'This is my stuff'
      })
      @asset = Asset.create(:file => io)
    end

    it "work" do
      @asset.file_name.must_equal 'foo.txt'
      @asset.file_size.must_equal 16
      @asset.file_type.must_equal 'plain/text'
      @asset.file.read.must_equal 'This is my stuff'
    end
  end

  describe "A font file" do
    before do
      @file = open_file('font.eot')
      @doc = Asset.create(:file => @file)
    end
    let(:subject) { @doc }

    it "assign joint keys" do
      subject.file_size.must_equal 17610
      subject.file_type.must_equal "application/octet-stream"
      subject.file_id.wont_be_nil
      subject.file_id.must_be_instance_of(BSON::ObjectId)
    end
  end

  describe "A music file" do
    before do
      @file = open_file('example.m4r')
      @doc = Asset.create(:file => @file)
    end
    let(:subject) { @doc }

    it "assign joint keys" do
      subject.file_size.must_equal 50790
      subject.file_type.must_equal "audio/mp4"
      subject.file_id.wont_be_nil
      subject.file_id.must_be_instance_of(BSON::ObjectId)
    end
  end
end
