![nginx 1.7.10](https://img.shields.io/badge/nginx-1.7.10-brightgreen.svg) ![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)

# docker-nginx-proxy

### Base Docker Image

[nginx:1.7.10](https://registry.hub.docker.com/_/nginx/)

### 説明

リバースプロキシサーバ として動作するコンテナです。

[Dockerについて](https://docs.docker.com/)  
[Docker Command Reference](https://docs.docker.com/reference/commandline/cli/)  
[docker-genについて](https://github.com/jwilder/docker-gen)

### 使用方法

git pull後に

    $ cd docker-nginx-proxy

イメージ作成

    $ docker build -t tanaka0323/nginx-proxy .

起動  

    $ docker run --name <name> -d \
                 -p 80:80 \
                 -p 443:443 \
                 -v /var/run/docker.sock:/tmp/docker.sock \
                 -ti tanaka0323/nginx-proxy

次にプロキシさせたい任意のコンテナを環境変数`VIRTUAL_HOST`を指定して実行

    $ docker run -e VIRTUAL_HOST=foo.bar.com  ...

### 利用可能なボリューム

以下のボリュームが利用可能

    /etc/nginx/certs    # nginx SSL認証ファイル

### マルチポートについて

指定のコンテナが複数のポートを公開している場合、nginxプロキシは、ポート80番上で実行されているサービスにデフォルト設定されます。  

別のポートを指定する必要がある場合は、以下の様に環境変数`VIRTUAL_PORT`を設定して下さい。

    $ docker run -e VIRTUAL_HOST=foo.bar.com VIRTUAL_PORT=8080 ...

指定のコンテナが1つだけのポートを公開し、環境変数`VIRTUAL_HOST`が設定されている場合は、そのポートが選択されます。

### マルチホストについて

指定のコンテナが複数の仮想ホストをサポートする必要がある場合は、カンマ区切りで以下の様に指定できます。

    $　docker run -e VIRTUAL_HOST=foo.bar.com,baz.bar.com,bar.com ...

### ワイルドカードホストについて

`*.bar.com`か`foo.bar.*`のように、最初とホスト名の末尾にワイルドカードを使用できます。

また[xip.io](http://xip.io)のような正規表現ワイルドカードDNSサービスと組み合わせると便利です。
`~^foo\.bar\..*\.xip\.io`のように指定すると`foo.bar.127.0.0.1.xip.io`、`foo.bar.10.0.2.2.xip.io`と全ての与えられたIPがマッチします。

さらに詳細について知りたい場合は、nginxドキュメントの[`server_names`](http://nginx.org/en/docs/http/server_names.html)を参考にして下さい。

### SSLバックエンド

HTTPではなくHTTPSを使用してバックエンドに接続したい場合は、バックエンドのコンテナに`VIRTUAL_PROTO=https`を設定します。

    $ docker run -e VIRTUAL_PROTO=https

### コンテナを分ける場合

nginx-proxyコンテナは公式 [nginx](https://registry.hub.docker.com/_/nginx/) イメージと [jwilder/docker-gen](https://index.docker.io/u/jwilder/docker-gen/) イメージを使用して2つの別々のコンテナとして実行することができます。  
コンテナを分けることにより、コンテナにバインド済みのDockerソケットをパブリックに公開されるのを防ぐことができます。  
別のコンテナとしてnginxのプロキシを実行し、使用しているホストOS上にnginx.tmplを配置する必要があります。

最初に共有ボリュームを指定しnginxを起動します。

    $ docker run -d -p 80:80 --name nginx -v /tmp/nginx:/etc/nginx/conf.d -t nginx

その後、共有ボリュームとテンプレートを指定し、docker-genコンテナを起動します。

    $ docker run --volumes-from nginx \
        -v /var/run/docker.sock:/tmp/docker.sock \
        -v $(pwd):/etc/docker-gen/templates \
        -t docker-gen -notify-sighup nginx -watch -only-published /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf

最後に、`VIRTUAL_HOST`環境変数を使用して、コンテナを開始します。

    $ docker run -e VIRTUAL_HOST=foo.bar.com  ...

### SSLサポート

SSLは、ワイルドカードや証明書の命名規則、または環境変数としてCERT名(SNIのため)を指定したSNI証明書を使用して、単一のホストとしてサポートされます。

SSLを有効にするには以下の様に指定

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/certs:/etc/nginx/certs -v /var/run/docker.sock:/tmp/docker.sock <tag>/nginx-proxy

/path/to/certs の内容は、使用中の任意の仮想ホスト用の証明書と秘密鍵が含まれている必要があります。
証明書と秘密鍵は、仮想ホストの中に.crtと.keyの拡張子を持ったファイル名であるべきです。

### ワイルドカード証明書

ワイルドカードの証明書と秘密鍵はドメイン名の後に.crtのと.keyの拡張子を持つ名前でなければなりません。  
例: `VIRTUAL_HOST=foo.bar.com`の場合、`bar.com.crt`と`bar.com.key`とする。

### SNI

もし証明書がマルチドメインをサポートしているなら、使用する証明書を識別するために環境変数`CERT_NAME=<name>`指定してコンテナを起動することができます。例えば、`*.foo.com`と`*.bar.com`をサポートしている証明書なら`shared.crt`と`shared.key`と名前を付けることができます。
環境変数`VIRTUAL_HOST=foo.bar.com`と`CERT_NAME=shared`が指定され実行されているコンテナは、この共有証明書を使用します。

### BASIC認証サポート

指定した環境変数`VIRTUAL_HOST`変数と同じ名前の `/etc/nginx/htpasswd/$VIRTUAL_HOST` ファイルを作成するとBASIC認証が有効になります。

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/htpasswd:/etc/nginx/htpasswd -v /path/to/certs:/etc/nginx/certs -v /var/run/docker.sock:/tmp/docker.sock jwilder/nginx-proxy

詳しくは、[こちら](http://httpd.apache.org/docs/2.2/programs/htpasswd.html)を参考にして下さい。

### Nginxのカスタム設定

環境変数で設定不可能なNginxの設定を行いたい場合は、プロキシ全体またはVIRTUAL_HOST毎にカスタム設定ファイルを指定することができます。

#### プロキシ全体設定

プロキシ全体に設定を指定するには、`.conf`拡張子のを持つファイルを/etc/nginx/conf.dの下に追加します。

RUNコマンドでファイルを作成、または`conf.d`にファイルをコピーするDockerfileから作成された、コンテナイメージで可能になります。

    FROM jwilder/nginx-proxy
    RUN { \
          echo 'server_tokens off;'; \
          echo 'client_max_body_size 100m;'; \
        } > /etc/nginx/conf.d/my_proxy.conf

または`docker run`コマンドでカスタム構成コンテナイメージを作成しても可能です。

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/my_proxy.conf:/etc/nginx/conf.d/my_proxy.conf:ro -v /var/run/docker.sock:/tmp/docker.sock jwilder/nginx-proxy

#### VIRTUAL_HOST毎設定

VIRTUAL_HOST毎に設定するには、`/etc/nginx/vhost.d`の下に設定ファイルを追加します。ファイル名はVIRTUAL_HOST毎に指定されたVIRTUAL_HOST変数と同じ名前にして下さい。

仮想ホストが動的にバックエンドに追加、削除されるようにするには、派生コンテナイメージを使用するか、個々の設定ファイルを外部ストレージコンテナの`/etc/nginx/vhost.d`にマウントするのが良い方法です。

例えば、`app.example.com`という名前の仮想ホストを持っている場合、以下のようにカスタム構成を設定することができます。

    $ docker run -d -p 80:80 -p 443:443 -v /path/to/vhost.d:/etc/nginx/vhost.d:ro -v /var/run/docker.sock:/tmp/docker.sock jwilder/nginx-proxy
    $ { echo 'server_tokens off;'; echo 'client_max_body_size 100m;'; } > /path/to/vhost.d/app.example.com

もし、単一のコンテナで複数のホスト名を使用している場合(例:`VIRTUAL_HOST=example.com,www.example.com`)、仮想ホストの設定ファイル名は、各ホスト名と同じにして下さい。
複数の仮想ホスト名で同じ設定を使用したい場合は、シンボリックリンクを使用することができます。

    $ { echo 'server_tokens off;'; echo 'client_max_body_size 100m;'; } > /path/to/vhost.d/www.example.com
    $ ln -s www.example.com /path/to/vhost.d/example.com

### WebSockerサポート

WebSockerコンテナをプロキシするには、以下のように環境変数`WEBSOCKETS=1`を設定します。

    $ docker run -e VIRTUAL_HOST=foo.bar.com -e WEBSOCKETS=1  ...

### License

The MIT License

Copyright (c) 2014 Jason Wilder

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

Copyright (c) 2015 Daisuke Tanaka

以下に定める条件に従い、本ソフトウェアおよび関連文書のファイル（以下「ソフトウェア」）の複製を取得するすべての人に対し、ソフトウェアを無制限に扱うことを無償で許可します。これには、ソフトウェアの複製を使用、複写、変更、結合、掲載、頒布、サブライセンス、および/または販売する権利、およびソフトウェアを提供する相手に同じことを許可する権利も無制限に含まれます。

上記の著作権表示および本許諾表示を、ソフトウェアのすべての複製または重要な部分に記載するものとします。

ソフトウェアは「現状のまま」で、明示であるか暗黙であるかを問わず、何らの保証もなく提供されます。ここでいう保証とは、商品性、特定の目的への適合性、および権利非侵害についての保証も含みますが、それに限定されるものではありません。 作者または著作権者は、契約行為、不法行為、またはそれ以外であろうと、ソフトウェアに起因または関連し、あるいはソフトウェアの使用またはその他の扱いによって生じる一切の請求、損害、その他の義務について何らの責任も負わないものとします。