CREATE TABLE config (
    key TEXT PRIMARY KEY,
    value TEXT
);

INSERT INTO config (key, value) VALUES
    ('database_host', 'localhost'),
    ('database_port', '5432'),
    ('database_user', 'admin'),
    ('database_password', 'secret with spaces'),
    ('api_url', 'https://api.example.com'),
    ('api_timeout', '30'); 