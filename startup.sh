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

read -t 30 -p "请输入项目名称，只允许[a-z]:" name


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

mkdir -p apps/${name}

pipenv run django-admin startapp ${name} apps/${name}

mkdir tmp

git clone https://github.com/tkliuxing/dj-usercenter.git tmp/dj-usercenter
git clone https://github.com/tkliuxing/dj-notice.git tmp/dj-notice
git clone https://github.com/tkliuxing/dj-baseconfig.git tmp/dj-baseconfig
git clone https://github.com/tkliuxing/dj-formtemplate.git tmp/dj-formtemplate
git clone https://github.com/tkliuxing/dj-flatdata.git tmp/dj-flatdata

mv tmp/dj-usercenter/usercenter apps/
mv tmp/dj-baseconfig/baseconfig apps/
mv tmp/dj-notice/notice apps/
mv tmp/dj-formtemplate/formtemplate apps/
mv tmp/dj-flatdata/flatdata apps/

rm -rf tmp

SECERT=`sed -n '23,23p' project/settings.py`

cat>project/settings.py<<EOF
import os
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(BASE_DIR, 'apps/'))

${SECERT}

DEBUG = True

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework_gis',
    'drf_yasg',
    'drf_generators',
    'django_filters',
    'mptt',
    'django_mptt_admin',
    'usercenter',
    'baseconfig',
    'notice',
    'formtemplate',
    'flatdata',
    '${name}',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'project.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'project.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}

AUTH_USER_MODEL = 'usercenter.User'

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 'zh-hans'

TIME_ZONE = 'Asia/Shanghai'

USE_I18N = True

USE_L10N = True

USE_TZ = False

STATIC_URL = '/static/'

MEDIA_ROOT = os.path.join(BASE_DIR, 'media/')

MEDIA_URL = '/media/'

STATIC_ROOT = os.path.join(BASE_DIR, 'static/')

REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'usercenter.pagination.UCPageNumberPagination',
    'PAGE_SIZE': 15,
    'DEFAULT_SCHEMA_CLASS': 'rest_framework.schemas.coreapi.AutoSchema',
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    ),
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_jwt.authentication.JSONWebTokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ),
}

JWT_AUTH = {
    'JWT_AUTH_HEADER_PREFIX': 'Bearer',
    'JWT_VERIFY_EXPIRATION': False,
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': True,
        },
        'django.db': {
            'handlers': ['console'],
            'level': 'INFO',    # change to DEBUG to view console log
            'propagate': True,
        },
        'restapi': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': True,
        },
    },
}

try:
    from .local_settings import *
except ImportError:
    raise ImportError('please create local_settings.py file')
EOF

cat>project/local_settings.py<<EOF
DEBUG = True

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '${name}',
        'USER': 'postgres',
        'PASSWORD': 'postgres',
        'HOST': 'localhost',
        'PORT': 5432
    }
}

ALLOWED_HOSTS = ['*']
EOF


cat>project/urls.py<<EOF
from django.conf import settings
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('', include('baseconfig.urls')),
    path('', include('usercenter.urls')),
    path('', include('notice.urls')),
    path('', include('formtemplate.urls')),
    path('', include('flatdata.urls')),
    path('', include('${name}.urls')),
    path('admin/', admin.site.urls),
]

if settings.DEBUG:
    from django.conf.urls.static import static
    from django.conf.urls import url
    from rest_framework.permissions import AllowAny
    from drf_yasg.views import get_schema_view
    from drf_yasg import openapi
    schema_view = get_schema_view(
        openapi.Info(
            title="API",
            default_version='v1',
            description="API接口文档",
            contact=openapi.Contact(email="xxx@xx.com"),
        ),
        public=True,
        permission_classes=(AllowAny,),
    )
    urlpatterns += [
        url(r'^swagger(?P<format>\.json|\.yaml)$', schema_view.without_ui(cache_timeout=0), name='schema-json'),
        url(r'^swagger/$', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
        url(r'^api-docs/$', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    ]
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
EOF


echo "生成完毕，请编辑'project/local_settings.py'，和'project/urls.py'文件以便配置项目"
