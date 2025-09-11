data "aws_organizations_organization" "this" {}

resource "aws_organizations_organizational_unit" "poc" {
  name      = "poc"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}
