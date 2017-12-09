require "test_helper"

class JTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::JLauncher::VERSION
  end

  def test_it_does_something_useful
    assert true
  end


  # puts local_repo.get(Coordinates.new({
  #     'groupId' => 'com.thoughtworks.proxytoys',
  #     'artifactId' => 'proxytoys',
  #     'version' => '1.0'
  # }))

end
