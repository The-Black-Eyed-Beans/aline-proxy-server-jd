FROM nginx

ENV ACCOUNT_SERVICE=account-microservice.account-jd.local
ENV BANK_SERVICE=bank-microservice.bank-jd.local
ENV TRANSACTION_SERVICE=transaction-microservice.transaction-jd.local
ENV UNDERWRITER_SERVICE=underwriter-microservice.underwriter-jd.local
ENV USER_SERVICE=user-microservice.user-jd.local

RUN rm /etc/nginx/conf.d/default.conf
COPY ./default.template /etc/nginx/conf.d/default.template

EXPOSE 80
RUN envsubst < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]