FROM nginx

RUN rm /etc/nginx/conf.d/default.conf
COPY ./default.template /etc/nginx/conf.d/default.template

EXPOSE 80
RUN envsubst < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]