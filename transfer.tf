resource "aws_transfer_server" "kantar_watermarking" {
  #checkov:skip=CKV_AWS_164: "Ensure Transfer Server is not exposed publicly."
  endpoint_type          = "PUBLIC"
  protocols              = ["SFTP"]
  domain                 = "S3"
  identity_provider_type = "SERVICE_MANAGED"
}

resource "aws_transfer_user" "habid" {
  server_id           = aws_transfer_server.kantar_watermarking.id
  user_name           = "habid"
  role                = aws_iam_role.user_role.arn
  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/"
    target = "/${module.source_bucket.id}"
  }
}

resource "aws_transfer_ssh_key" "habid" {
  server_id = aws_transfer_server.kantar_watermarking.id
  user_name = aws_transfer_user.habid.user_name
  body      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFEvM7OptzJIoCR857OetMnuJ2WnVdZey+pFhItUNzY/QkB9s1tvozFBZE3EDC7odrit5BAX1ofC01bSsZEMac6gPUjKQ/2O7YKHJwmK5Fk8sCRvM7NTgRurQT52L7EurkzgIGWZv6H2Da71SyD5GlFZ/q7yYMkYihoAZfid1IDKrRSNvLdoesl+FxGGt41Yy6MSZn9olglyr+nkWvkZPsN7Rg73p/P/MUcGV5MVM/XoW8+JkmayAK7a+EtbzSJY7i0lZtWAqO0VhDZ3MaWWR8qvOIhhNtAeFatT1Jx8n8dlXUD9I6dIXMftZHupJWZwFY8oIqmZZPvjVrma/ts8dYTlojSUs8NkqZYR2Wq6Z7ZRo2bIj1INww89HtCnZaNn1jEGuQbBTBuVSx78XWgZ2pOzTBWFjXvkzM72mBssxnA0jn9/pVe7wx0DIhGvoN6IZNZOlZVhX/toJOAFYaiX/vZHXE73xyTry403cjQEeJ79Rqy0OiHVypwEryRDBJbgk= hicham.abid.prestataire@alticemedia.com"
}


resource "aws_transfer_user" "lcarriere" {
  server_id           = aws_transfer_server.kantar_watermarking.id
  user_name           = "lcarriere"
  role                = aws_iam_role.user_role.arn
  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/"
    target = "/${module.source_bucket.id}"
  }
}

resource "aws_transfer_ssh_key" "lcarriere" {
  server_id = aws_transfer_server.kantar_watermarking.id
  user_name = aws_transfer_user.lcarriere.user_name
  body      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDl2YDSxqi/wlD9Vux6B7KXjiihpVc3fyP4StNdQem7mZgYz7R61dNxAvFF5DoMfGACzf7joZxS/0dv5vt49POFOfnka/Zsw8j61O103BRnpqB4MDB8UyFmLSTORyTC1tx+yK6Io2ZB3dx3p79XaeBdStfSzEdHBF3EHj5p7TaUqOSXyDXMJ/1KuXbre6b6qL/Es6rvPLtIgmqb75S9t4xTNxtJRwdIjtS/iOcBClGlz3ntoEuN870xbAoPIrfs8sX+VijJIwjItKd0AaairMcvl/y/CRUUIABnhv9SnJGpBWDscjFtxLB6sLz8DUCu2COthuqFdIMzbsHK3obXbaTEw8FTlkeEJW85+C0ATVPmNon00rP8uoMtir3J5RJyyUncIfzjaBLO6eEEHcMU5Ig4Rk3nj0SvuIn/v12hTIdJaBvtDojxIMG6HUA6Dj0mvU7d7KQFqRtrQFwvHgUpmlK01C6i2sELhXSTgkURfypls3DxKY9chdMo0yMhevRWijs= lise.carriere@alticemedia.com"
}
