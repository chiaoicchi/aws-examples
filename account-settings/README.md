# AWS account settings

## Abstruct

AWS 全体のアカウント設定に関するコードサンプルです。

> [!IMPORTANT]
> このTerraform構成を使用する前に、以下の事項をAWSマネジメントコンソールにて手動で設定していることを確認してください。
> 1. AWS Organizationsはルート（管理）アカウントから手動で有効化してください。
> 2. AWS Identity Center も同じくルートアカウントから手動で有効化してください。
> 3. これらのサービスはTerraformで有効化しないでください。有効化は不可逆的な操作であり、自動化すると予期せぬ影響が生じる可能性があります。
> 4. 以降のTerraformリソースは、OrganizationsおよびIdentity Centerがルートアカウントで既に有効化および設定されていることを前提としています。
>
> これらのサービスは、適切なアクセス権と一元管理を確保するため、必ずAWS Organizationsの管理（ルート）アカウントから有効化してください。
> このTerraform構成を使用する前に、以下の事項をAWSマネジメントコンソールにて手動で設定していることを確認してください。

## How to use

### 前準備

1. AWS Organizations をルートアカウントから手動で有効化します。
2. AWS Identity Center も同じくルートアカウントから手動で有効化します。

### Terraform

Terraform コードを apply してください。

### アカウントの追加

アカウントを追加する際は、 Terraform ではなく手動で行ってください。
その後、 Terraform リソースを reapply すると、 admin グループに AdministratorAccess が割り当てられます。
