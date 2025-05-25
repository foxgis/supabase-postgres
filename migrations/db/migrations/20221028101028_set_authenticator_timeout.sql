-- migrate:up
alter role authenticator set statement_timeout = '60s';

-- migrate:down

