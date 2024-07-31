# Django 앱 이미지 푸시
resource "null_resource" "push_django_image" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = <<EOF
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_ecr_repository.django_app.repository_url}
cd tickettopia
echo "${var.ENV_FILE_CONTENT}" > .env
docker build -t 0415bichan/django-app:${var.IMAGE_TAG} .
docker tag 0415bichan/django-app:${var.IMAGE_TAG} ${data.aws_ecr_repository.django_app.repository_url}:${var.IMAGE_TAG}
docker push ${data.aws_ecr_repository.django_app.repository_url}:${var.IMAGE_TAG}
rm .env
EOF
  }
}

# ECS 서비스가 새 이미지를 사용하도록 강제 업데이트
resource "null_resource" "force_ecs_deployment" {
  triggers = {
    django_image_update = null_resource.push_django_image.id
  }

  provisioner "local-exec" {
    command = "aws ecs update-service --cluster ${data.aws_ecs_cluster.main.cluster_name} --service ${data.aws_ecs_service.app.service_name} --force-new-deployment --region ap-northeast-2"
  }

  depends_on = [null_resource.push_django_image]
}

# 기존 리소스 참조를 위한 data 소스 추가
data "aws_ecr_repository" "django_app" {
  name = "django-app-repo"
}

data "aws_ecs_cluster" "main" {
  cluster_name = "main-cluster"
}

data "aws_ecs_service" "app" {
  cluster_arn = data.aws_ecs_cluster.main.arn
  service_name = "app-service"
}

# 환경변수로 이미지 태그 받기
variable "IMAGE_TAG" {
  description = "The tag for the Docker image"
  type        = string
}

# GitHub Actions secret으로부터 .env 파일 내용을 받기 위한 변수
variable "ENV_FILE_CONTENT" {
  description = "Content of the .env file"
  type        = string
}