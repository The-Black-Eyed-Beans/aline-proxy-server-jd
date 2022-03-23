FROM nginx

ENV USER_SERVICE=user-microservice.user.local
ENV UNDERWRITER_SERVICE=underwriter-microservice.underwriter.local
ENV ACCOUNT_SERVICE=account.account-microservice.local
ENV TRANSACTION_SERVICE=transaction-microservice.transaction.local
ENV BANK_SERVICE=bank-microservice.bank.local

RUN rm /etc/nginx/conf.d/default.conf
COPY ./default.template /etc/nginx/conf.d/default.template

EXPOSE 80
RUN envsubst < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]