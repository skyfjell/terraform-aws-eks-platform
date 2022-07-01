/************************
        Role def 
*************************/

data "aws_iam_policy_document" "this_assume_policy_doc" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = sort(toset(local.user_arns))
    }

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = [true]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = "${local.labels.id}-${local.name}"
  assume_role_policy   = data.aws_iam_policy_document.this_assume_policy_doc.json
  max_session_duration = local.max_session_duration
  tags                 = local.labels.tags
}

// Role actions

data "aws_iam_policy_document" "this_action" {
  count = local.attach ? 1 : 0

  statement {
    effect = "Allow"

    actions   = local.actions
    resources = [local.cluster_arn]
  }
}

resource "aws_iam_policy" "this_action_policy" {
  count = local.attach ? 1 : 0

  name   = "${local.labels.id}-${local.name}-action"
  policy = data.aws_iam_policy_document.this_action[0].json
  tags   = local.labels.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  count = local.attach ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this_action_policy[0].arn
}

/************************
        Group def 
*************************/

resource "aws_iam_group" "this" {
  name = "${local.labels.id}-${local.name}"
}

resource "aws_iam_group_membership" "this" {
  //checkov:skip=CKV2_AWS_21:Only running on File not planned
  //checkov:skip=CKV2_AWS_14:Only running on File not planned
  name  = "${local.labels.id}-${local.name}"
  group = aws_iam_group.this.id
  users = sort([for user in local.user_arns : replace(user, "/^[^/]+//", "")])
}

// Group actions

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.this.arn]
  }
}

resource "aws_iam_policy" "this" {
  name   = "${local.labels.id}-${local.name}-assume"
  policy = data.aws_iam_policy_document.this.json
  tags   = local.labels.tags
}

resource "aws_iam_group_policy_attachment" "this" {
  group      = aws_iam_group.this.name
  policy_arn = aws_iam_policy.this.arn
}
