FROM nginx

ENV USER_SERVICE=user.user.local
ENV UNDERWRITER_SERVICE=underwriter.underwriter.local
ENV ACCOUNT_SERVICE=account.account.local
ENV TRANSACTION_SERVICE=transaction.transaction.local
ENV BANK_SERVICE=bank.bank.local

RUN rm /etc/nginx/conf.d/default.conf
COPY ./default.template /etc/nginx/conf.d/default.template

EXPOSE 80
RUN envsubst < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]