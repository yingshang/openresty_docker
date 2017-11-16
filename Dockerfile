from centos:7
RUN yum install  -y readline-devel pcre-devel openssl-devel gcc wget lua-devel git gcc gcc-c++  make gmake vim unzip
RUN cd /opt && wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.41.tar.gz && tar zxvf pcre-8.41.tar.gz 
#https://www.kyne.com.au/~mark/software/lua-cjson-manual.html#_installation 
#cjson安装手册
RUN cd /opt && wget https://www.kyne.com.au/~mark/software/download/lua-cjson-2.1.0.tar.gz && tar zxvf lua-cjson-2.1.0.tar.gz && cd lua-cjson-2.1.0 && sed -i 's/\/usr\/local/\/usr\/share\/lua\/5.1/g' Makefile
RUN cd /opt && wget https://openresty.org/download/openresty-1.11.2.5.tar.gz &&  tar zxvf openresty-1.11.2.5.tar.gz &&  cd openresty-1.11.2.5 && ./configure --with-pcre=/opt/pcre-8.41  --with-pcre-jit && make && make install 
RUN mkdir /data/ && mkdir /data/waf && chmod 777 /data/waf
RUN ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/sbin/nginx
RUN cd /opt/ && wget http://luarocks.github.io/luarocks/releases/luarocks-2.4.3.tar.gz && tar zxvf luarocks-2.4.3.tar.gz && cd luarocks-2.4.3 && ./configure && make build && make install 
RUN luarocks install luafilesystem
#RUN cd /opt && wget http://debuginfo.centos.org/7/x86_64/kernel-debuginfo-3.10.0-514.el7.x86_64.rpm 
#RUN cd /opt && wget http://debuginfo.centos.org/7/x86_64/kernel-debuginfo-common-x86_64-3.10.0-514.el7.x86_64.rpm
#RUN cd /opt && rpm -ivh kernel-debuginfo-common-x86_64-3.10.0-514.el7.x86_64.rpm 
#RUN cd /opt && rpm -ivh kernel-debuginfo-3.10.0-514.el7.x86_64.rpm 
#RUN cd /opt && wget ftp://ftp.pbone.net/mirror/ftp.scientificlinux.org/linux/scientific/7.3/x86_64/os/Packages/kernel-devel-3.10.0-514.el7.x86_64.rpm && rpm -vih #kernel-devel-3.10.0-514.el7.x86_64.rpm
#RUN yum install  -y systemtap
#RUN mkdir -p /lib/modules/3.10.0-693.5.2.el7.x86_64/build/ 
#RUN ln -s /usr/src/kernels/3.10.0-514.el7.x86_64/.config /lib/modules/3.10.0-693.5.2.el7.x86_64/build/.config
#RUN ln -s /usr/src/kernels/3.10.0-514.el7.x86_64/Module.symvers  /lib/modules/3.10.0-693.5.2.el7.x86_64/build/Module.symvers
#RUN yum install -y gettext elfutils-devel elfutils  kernel-devel
#RUN cd /opt && git clone git://sourceware.org/git/systemtap.git
#RUN cd /opt && cd systemtap/ && ./configure && make && make install 

ADD waf /usr/local/openresty/nginx/conf/waf/
COPY nginx.conf /usr/local/openresty/nginx/conf/
ENTRYPOINT nginx && tail /data/waf/waf.log





##nginx conf
#access_by_lua_file /usr/local/openresty/nginx/conf/waf/waf.lua;
#                location / {
#proxy_pass   http://192.168.8.89:8881/;
#                }
#        }
