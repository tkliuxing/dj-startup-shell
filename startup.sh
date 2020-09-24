#!/bin/sh


echo "Test!"

# Test command exist

commands=( 'pipenv' 'pyenv' 'git' )

for i in ${commands[@]};
do
	if ! command -v ${i} >/dev/null 2>&1; then
		echo "${i} not exists"
		exit -1
	fi
done


read "请输入项目名称，只允许[a-z]:" name


# Generate Pipfile

cat>Pipfile<<EOF
[[source]]
name = "pypi"
url = "https://mirrors.aliyun.com/pypi/simple"
verify_ssl = true

[dev-packages]
ipython = "*"

[packages]
django = "<3.0"
djangorestframework = "*"
djangorestframework-jwt = "*"
djangorestframework-gis = "*"
django-mptt = "*"
django-mptt-admin = "*"
wechatpy = {extras = ["cryptography"],version = "*"}
django-filter = "*"
drf-yasg = "*"
pyyaml = "*"
psycopg2-binary = "*"
Pillow = "*"
coreapi = "*"
drf-generators = {git = "https://github.com/tkliuxing/drf-generators.git"}
django-model-utils = ">=1.4.0"
numpy = "*"
pandas = "*"
django-pandas = "*"
redis = "*"
docxtpl = "*"
python-barcode = "*"
jieba = "*"
pyodbc = "*"
django-mssql-backend = "*"

[requires]
python_version = "3.7"
EOF


# Install python enviroument

pipenv install --python 3.7

pipenv run django-admin startproject project .

cat>>project/settings.py<<EOF
try:
    from .local_settings import *
except ImportError:
    raise ImportError('please create local_settings.py file')
EOF

mkdir -p apps/${name}

pipenv run django-admin startapp ${name} apps/${name}

mkdir tmp

git clone https://github.com/tkliuxing/dj-usercenter.git tmp/dj-usercenter
git clone https://github.com/tkliuxing/dj-notice.git tmp/dj-notice
git clone https://github.com/tkliuxing/dj-baseconfig.git tmp/dj-baseconfig

mv tmp/dj-usercenter/usercenter apps/
mv tmp/dj-baseconfig/baseconfig apps/
mv tmp/dj-notice/notice apps/

rm -rf tmp

echo "生成完毕，请编辑'project/settiings.py'，并创建'project/local_settings.py'文件"
