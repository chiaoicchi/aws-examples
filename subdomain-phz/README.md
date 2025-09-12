# subdomain public hosted zone

## Abstruct

別のアカウントに public hosted zone として登録されているドメインのサブドメインに関するコードサンプルです。
サブドメイン用の public hosted zone を作成し、名前解決を委任します。

## How to use

ドメインの PHZ があるアカウントで、 `parent_phz` を apply します。

サブドメインの PHZ を作成したいアカウントで、 `sub_phz` を apply します。
