data "aws_ssoadmin_instances" "this" {}

resource "aws_identitystore_group" "admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  display_name      = "admin"
}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "admin"
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  session_duration = "PT8H"
  tags             = var.tags
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

resource "aws_ssoadmin_account_assignment" "admin" {
  count = length(data.aws_organizations_organization.this.accounts)

  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.admin.group_id
  principal_type     = "GROUP"
  target_id          = data.aws_organizations_organization.this.accounts[count.index].id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_identitystore_user" "admin" {
  for_each = var.admin_users

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  user_name         = each.key
  display_name      = each.value.display_name
  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }
  emails {
    value = each.value.email
  }
}

resource "aws_identitystore_group_membership" "admin" {
  for_each = aws_identitystore_user.admin

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  group_id          = aws_identitystore_group.admin.group_id
  member_id         = each.value.user_id
}
