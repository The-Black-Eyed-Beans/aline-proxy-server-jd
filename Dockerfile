FROM nginx

ENV ACCOUNT_SERVICE=${ACCOUNT_SERVICE}
ENV BANK_SERVICE=${BANK_SERVICE}
ENV TRANSACTION_SERVICE=${TRANSACTION_SERVICE}
ENV UNDERWRITER_SERVICE=${UNDERWRITER_SERVICE}
ENV USER_SERVICE=${USER_SERVICE}

RUN rm /etc/nginx/conf.d/default.conf
COPY ./default.template /etc/nginx/conf.d/default.template

EXPOSE 80
RUN envsubst < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]