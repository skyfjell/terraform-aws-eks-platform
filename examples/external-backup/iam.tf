resource "aws_iam_user" "test_edit" {
  name = "tf-aws-eks-platform-test-edit"
}

resource "aws_iam_user" "test_view" {
  name = "tf-aws-eks-platform-test-view"
}
