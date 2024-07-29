# ECR 리포지토리에 이미지 푸시
resource "null_resource" "push_images" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOF
      # AWS ECR 로그인
      aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.django_app.repository_url}
      aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.nginx.repository_url}

      # Django 애플리케이션 이미지 푸시
      docker pull wangamy/ttopia-re:latest
      docker tag wangamy/ttopia-re:latest ${aws_ecr_repository.django_app.repository_url}:latest
      docker push ${aws_ecr_repository.django_app.repository_url}:latest

      # Nginx 이미지 푸시 (기본 Nginx 이미지 사용)
      docker pull nginx:latest
      docker tag nginx:latest ${aws_ecr_repository.nginx.repository_url}:latest
      docker push ${aws_ecr_repository.nginx.repository_url}:latest
    EOF
  }

  depends_on = [aws_ecr_repository.django_app, aws_ecr_repository.nginx]
}