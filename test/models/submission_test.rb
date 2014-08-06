require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  test "Valid solution for A+B Problem" do
    # skip "Until judge method is implemented"
    submissions(:valid).judge!
    assert_equal "OK", submissions(:valid).status
  end

  test "Wrong answer for A+B Problem" do

  end

  test "MLE for A+B Problem" do
    submissions(:mle).judge!
    assert_equal "MLE", submissions(:mle).status
  end

  test "RTE for A+B Problem" do
    submissions(:rte).judge!
    assert_equal "RTE", submissions(:rte).status
  end
  # test "the truth" do
  #   assert true
  # end
end
