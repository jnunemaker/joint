require 'helper'

class Asset
  include MongoMapper::Document
  plugin Joint

  key :title, String
  attachment :image
  attachment :file
end

module JointTestHelpers
  def all_files
    [@file, @image, @image2, @test1, @test2]
  end

  def rewind_files
    all_files.each { |f| f.rewind }
  end

  def open_file(name)
    File.open(File.join(File.dirname(__FILE__), 'fixtures', name), 'r')
  end

  def grid
    @grid ||= Mongo::Grid.new(MongoMapper.database)
  end
end

class JointTest < Test::Unit::TestCase
  include JointTestHelpers

  def setup
    super
    @file   = open_file('unixref.pdf')
    @image  = open_file('mr_t.jpg')
    @image2 = open_file('harmony.png')
    @test1  = open_file('test1.txt')
    @test2  = open_file('test2.txt')
  end

  def teardown
    all_files.each { |f| f.close }
  end

  context "Using Joint plugin" do
    should "add each attachment to attachment_names" do
      Asset.attachment_names.should == Set.new([:image, :file])
    end

    should "add keys for each attachment" do
      [:image, :file].each do |attachment|
        [:id, :name, :type, :size].each do |key|
          Asset.keys.should include("#{attachment}_#{key}")
        end
      end
    end
  end

  context "Assigning new attachments to document" do
    setup do
      @doc = Asset.create(:image => @image, :file => @file)
      @doc.reload
      rewind_files
    end
    subject { @doc }

    should "assign GridFS content_type" do
      grid.get(subject.image_id).content_type.should == 'image/jpeg'
      grid.get(subject.file_id).content_type.should == 'application/pdf'
    end

    should "assign joint keys" do
      subject.image_size.should  == 13661
      subject.file_size.should   == 68926

      subject.image_type.should  == "image/jpeg"
      subject.file_type.should   == "application/pdf"

      subject.image_id.should_not be_nil
      subject.file_id.should_not be_nil

      subject.image_id.should be_instance_of(Mongo::ObjectID)
      subject.file_id.should be_instance_of(Mongo::ObjectID)
    end

    should "allow accessing keys through attachment proxy" do
      subject.image.size.should  == 13661
      subject.file.size.should   == 68926

      subject.image.type.should  == "image/jpeg"
      subject.file.type.should   == "application/pdf"

      subject.image.id.should_not be_nil
      subject.file.id.should_not be_nil

      subject.image.id.should be_instance_of(Mongo::ObjectID)
      subject.file.id.should be_instance_of(Mongo::ObjectID)
    end

    should "proxy unknown methods to GridIO object" do
      subject.image.files_id.should      == subject.image_id
      subject.image.content_type.should  == 'image/jpeg'
      subject.image.filename.should      == 'mr_t.jpg'
      subject.image.file_length.should   == 13661
    end

    should "assign file name from path if original file name not available" do
      subject.image_name.should  == 'mr_t.jpg'
      subject.file_name.should   == 'unixref.pdf'
    end

    should "save attachment contents correctly" do
      subject.file.read.should   == @file.read
      subject.image.read.should  == @image.read
    end

    should "know that attachment exists" do
      subject.image?.should be(true)
      subject.file?.should be(true)
    end

    should "clear assigned attachments so they don't get uploaded twice" do
      Mongo::Grid.any_instance.expects(:put).never
      subject.save
    end
  end

  context "Updating existing attachment" do
    setup do
      @doc = Asset.create(:image => @image)
      @doc.reload
      assert_no_grid_difference do
        @doc.image = @image2
        @doc.save!
      end
      rewind_files
    end
    subject { @doc }

    should "not change attachment id" do
      subject.image_id_changed?.should be(false)
    end

    should "update keys" do
      subject.image_name.should == 'harmony.png'
      subject.image_type.should == "image/png"
      subject.image_size.should == 213517
    end

    should "update GridFS" do
      grid.get(subject.image_id).filename.should     == 'harmony.png'
      grid.get(subject.image_id).content_type.should == 'image/png'
      grid.get(subject.image_id).file_length.should  == 213517
      # grid.get(subject.image_id).read.should         == @image2.read
    end
  end

  context "Updating document but not attachments" do
    setup do
      @doc = Asset.create(:image => @image)
      @doc.update_attributes(:title => 'Updated')
      @doc.reload
      rewind_files
    end
    subject { @doc }

    should "not affect attachment" do
      subject.image.read.should == @image.read
    end

    should "update document attributes" do
      subject.title.should == 'Updated'
    end
  end

  context "Assigning file where file pointer is not at beginning" do
    setup do
      @image.read
      @doc = Asset.create(:image => @image)
      @doc.reload
      rewind_files
    end
    subject { @doc }

    should "rewind and correctly store contents" do
      subject.image.read.should == @image.read
    end
  end

  context "Setting attachment to nil" do
    setup do
      @doc = Asset.create(:image => @image)
      rewind_files
    end
    subject { @doc }

    should "delete attachment after save" do
      assert_no_grid_difference   { subject.image = nil }
      assert_grid_difference(-1)  { subject.save }
    end

    should "clear nil attachments after save and not attempt to delete again" do
      Mongo::Grid.any_instance.expects(:delete).once
      subject.image = nil
      subject.save
      Mongo::Grid.any_instance.expects(:delete).never
      subject.save
    end
  end

  context "Retrieving attachment that does not exist" do
    setup do
      @doc = Asset.create
      rewind_files
    end
    subject { @doc }

    should "know that the attachment is not present" do
      subject.image?.should be(false)
    end

    should "raise Mongo::GridError" do
      assert_raises(Mongo::GridError) { subject.image.read }
    end
  end

  context "Destroying a document" do
    setup do
      @doc = Asset.create(:image => @image)
      rewind_files
    end
    subject { @doc }

    should "remove files from grid fs as well" do
      assert_grid_difference(-1) { subject.destroy }
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