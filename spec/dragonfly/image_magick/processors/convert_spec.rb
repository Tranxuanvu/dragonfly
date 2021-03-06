require 'spec_helper'

describe Dragonfly::ImageMagick::Processors::Convert do

  def sample_content(name)
    Dragonfly::Content.new(app, SAMPLES_DIR.join(name))
  end

  let(:app){ test_app }
  let(:image){ sample_content('beach.png') } # 280x355
  let(:pdf){ sample_content('memo.pdf') }
  let(:processor){ Dragonfly::ImageMagick::Processors::Convert.new }

  it "should allow for general convert commands" do
    processor.call(image, '-scale 56x71')
    image.should have_width(56)
    image.should have_height(71)
  end

  it "should allow for general convert commands with added format" do
    processor.call(image, '-scale 56x71', 'format' => 'gif')
    image.should have_width(56)
    image.should have_height(71)
    image.should have_format('gif')
    image.meta['format'].should == 'gif'
  end

  it "should work for commands with parenthesis" do
    processor.call(image, "\\( +clone -sparse-color Barycentric '0,0 black 0,%[fx:h-1] white' -function polynomial 2,-2,0.5 \\) -compose Blur -set option:compose:args 15 -composite")
    image.should have_width(280)
  end

  it "should work for files with spaces in the name" do
    image = Dragonfly::Content.new(app, SAMPLES_DIR.join('white pixel.png'))
    processor.call(image, "-resize 2x2!")
    image.should have_width(2)
  end

  it "updates the url with format if given" do
    url_attributes = Dragonfly::UrlAttributes.new
    processor.update_url(url_attributes, '-scale 56x71', 'format' => 'gif')
    url_attributes.ext.should == 'gif'
  end

  it "allows converting specific frames" do
    gif = sample_content('gif.gif')
    processor.call(gif, '-resize 50x50')
    all_frames_size = gif.size

    gif = sample_content('gif.gif')
    processor.call(gif, '-resize 50x50', 'frame' => 0)
    one_frame_size = gif.size

    one_frame_size.should < all_frames_size
  end

  it "accepts input arguments for convert commands" do
    pdf2 = pdf.clone
    processor.call(pdf, '-scale 85x110', 'format' => 'png')
    processor.call(pdf2, '-scale 85x110', 'format' => 'png', 'input_args' => '-density 150')

    pdf.should_not equal_image(pdf2)
  end

  it "allows converting using specific delegates" do
    expect {
      processor.call(image, '', 'format' => 'jpg', 'delegate' => 'png')
    }.to call_command(app.shell, %r{'convert' 'png:/[^']+?/beach\.png' '/[^']+?\.jpg'})
  end
end
