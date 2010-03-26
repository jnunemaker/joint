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
    @grid = Mongo::Grid.new(MongoMapper.database)

    dir    = File.dirname(__FILE__) + '/fixtures'    
    @pdf   = File.open("#{dir}/unixref.pdf",  'r')
    @image = File.open("#{dir}/mr_t.jpg", 'r')

    @pdf_contents   = File.read("#{dir}/unixref.pdf")
    @image_contents = File.read("#{dir}/mr_t.jpg")

    @doc = Foo.create(:image => @image, :pdf => @pdf)
    @doc.reload
  end

  def teardown
    @pdf.close
    @image.close
  end

  test "assigns keys correctly" do
    assert_equal 13661, @doc.image_size
    assert_equal 68926,  @doc.pdf_size

    assert_equal "image/jpeg",       @doc.image_type
    assert_equal "application/pdf", @doc.pdf_type

    assert_not_nil @doc.image_id
    assert_not_nil @doc.pdf_id
    assert_kind_of Mongo::ObjectID, @doc.image_id
    assert_kind_of Mongo::ObjectID, @doc.pdf_id

    assert_equal "image/jpeg", @grid.get(@doc.image_id).content_type
    assert_equal "application/pdf", @grid.get(@doc.pdf_id).content_type
  end

  test "assigns file name from path if original file name not available" do
    assert_equal 'mr_t.jpg', @doc.image_name
    assert_equal 'unixref.pdf',  @doc.pdf_name
  end

  test "assigns file name from original filename if available" do
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

  test "responds to keys" do
    [ :pdf_size,   :pdf_id,   :pdf_name,   :pdf_type,
      :image_size, :image_id, :image_name, :image_type
    ].each do |method|
      assert @doc.respond_to?(method)
    end
  end

  test "saves attachments correctly" do
    assert_equal @pdf_contents, @doc.pdf.read
    assert_equal @image_contents, @doc.image.read
  end

  test "cleans up attachments on destroy" do
    @doc.destroy
    assert_raises(Mongo::GridError) { @grid.get(@doc.image_id) }
    assert_raises(Mongo::GridError) { @grid.get(@doc.pdf_id) }
  end
end