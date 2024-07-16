FROM debian:latest

RUN apt update -y && apt upgrade -y \
	&& apt install -y nginx git libxslt-dev libperl-dev \
	bison build-essential ca-certificates curl dh-autoreconf doxygen \
	flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev \
	libpcre3-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales liblua5.3-dev \
	pkg-config wget zlib1g-dev libgd-dev \
	&& mkdir /etc/nginx/ssl \
	&& apt install openssl -y \
    && openssl req -x509 -nodes -out /etc/nginx/ssl/transcendance.crt \
    -keyout /etc/nginx/ssl/transcendance.key -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=transcendance.42.fr/UID=transcendance" \
	&& cd /opt && git clone https://github.com/owasp-modsecurity/ModSecurity \
	&& cd ModSecurity && git submodule init && git submodule update \
	&& ./build.sh && ./configure && make && make install \
	&& cd /opt && git clone https://github.com/owasp-modsecurity/ModSecurity-nginx \
	&& wget http://nginx.org/download/nginx-1.22.1.tar.gz && tar -xvzmf nginx-1.22.1.tar.gz \
	&& cd nginx-1.22.1 \
	&& ./configure --with-cc-opt='-g -O2 -ffile-prefix-map=/build/nginx-AoTv4W/nginx-1.22.1=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=stderr --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-compat --with-debug --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_secure_link_module --with-http_sub_module --with-mail_ssl_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-stream_realip_module --with-http_geoip_module=dynamic --with-http_image_filter_module=dynamic --with-http_perl_module=dynamic --with-http_xslt_module=dynamic --with-mail=dynamic --with-stream=dynamic --with-stream_geoip_module=dynamic --add-dynamic-module=../ModSecurity-nginx \
	&& make modules \
	&& mkdir /etc/nginx/modules \
	&& cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN cd opt/ && git clone https://github.com/coreruleset/coreruleset.git modsecurity-crs \
	&& cd modsecurity-crs && mv crs-setup.conf.example crs-setup.conf \
	&& mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf \
	&& cd ../ && mv modsecurity-crs /usr/local/ \
	&& mkdir -p /etc/nginx/modsec \
	&& cp ModSecurity/unicode.mapping /etc/nginx/modsec/ \
	&& mv ModSecurity/modsecurity.conf-recommended ModSecurity/modsecurity.conf

COPY conf/modsecurity.conf /etc/nginx/modsec/

COPY conf/modsecurity.conf /opt/ModSecurity/

COPY conf/main.conf /etc/nginx/modsec/

COPY conf/default /etc/nginx/sites-available/

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
