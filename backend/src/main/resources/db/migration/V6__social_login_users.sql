ALTER TABLE users
    ADD COLUMN provider       VARCHAR(20)  NOT NULL DEFAULT 'email',
    ADD COLUMN provider_id    VARCHAR(255),
    ADD COLUMN widget_enabled BOOLEAN      NOT NULL DEFAULT false;

ALTER TABLE users ALTER COLUMN password DROP NOT NULL;

ALTER TABLE users
    ADD CONSTRAINT users_provider_provider_id_key UNIQUE (provider, provider_id);
