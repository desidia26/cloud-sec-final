resource "aws_ecr_repository" "victim" {
  name         = "victim"
  force_delete = true
}

resource "aws_ecr_repository" "attacker" {
  name         = "attacker"
  force_delete = true
}

resource "null_resource" "push_images" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = "/bin/bash ${path.module}./go-servers/build.sh ALL latest"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "/bin/bash -c echo \"Image deletion handled by ecr deletion\""
  }
  depends_on = [aws_ecr_repository.victim, aws_ecr_repository.attacker]
}
