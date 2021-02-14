
### Порядок развертывания приложения:
1. В файле env.sh необходимо отредактировать значения переменных, внеся реальные credentials Amazon и пароль для БД Wordpress.

2. В каталоге terraform необходимо сгенерировать ключевую пару ssh (**admin_private.key, admin_private.key.pub**), которая будет использоваться в процессе развертывания ec2 инстансов для Wordpress.
```shell
  ssh-keygen -b 2048 -t rsa -f admin_private.key -q -N ""
```
3. Для работы provisioner-а требуется установка коллекции **ansible.posix**:
```shell
  ansible-galaxy collection install ansible.posix
```
4. Запуск процедуры:
   ```shell
   epam_aws_hw$ cd terraform
   epam_aws_hw/terraform$ source ../env.sh
   epam_aws_hw/terraform$ terraform init
   epam_aws_hw/terraform$ terraform apply
   ```
В конце процедуры на экран будут выведены IP адреса инстансов Wordpress и DNS имя load balancer-а, по которому будет доступно развернутое приложение:
```shell
Outputs:
aws_instance_wp1_public_ip = "54.218.74.237"
aws_instance_wp2_public_ip = "54.202.239.77"
aws_lb_dns_name = "epam-aws-homework-LB-wpress-100364250.us-west-2.elb.amazonaws.com"
```
