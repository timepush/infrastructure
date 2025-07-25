
-- 1. Types
create type user_login_type as enum ('manual', 'google', 'facebook');
create type provider_role as enum ('owner', 'editor', 'viewer');

-- 2. Base tables (no FKs)
create table if not exists data_source_types (
    id uuid default gen_random_uuid() not null,
    name varchar(50) not null,
    description text,
    created_at timestamp with time zone default now() not null,
    primary key (id),
    unique (name)
);

create table if not exists aggregation_types (
    id uuid default gen_random_uuid() not null,
    name varchar(20) not null,
    description text,
    created_at timestamp with time zone default now() not null,
    primary key (id),
    unique (name)
);

create table if not exists data_providers (
    id uuid default gen_random_uuid() not null,
    name varchar(255) not null,
    created_at timestamp with time zone default now() not null,
    primary key (id)
);

create table if not exists components (
    id uuid default gen_random_uuid() not null,
    name varchar(255) not null,
    description text,
    created_at timestamp with time zone default now() not null,
    primary key (id),
    unique (name)
);

-- 3. Dependent tables
create table if not exists users (
    id uuid default gen_random_uuid() not null,
    email text not null,
    first_name varchar(100) not null,
    last_name varchar(100) not null,
    login_type user_login_type not null,
    external_id varchar(255),
    password_hash text,
    is_admin boolean default false not null,
    is_verified boolean default false not null,
    current_data_provider_id uuid,
    created_at timestamp with time zone default now() not null,
    primary key (id),
    unique (login_type, external_id),
    unique (email),
    constraint chk_login_fields check (
        ((login_type = 'manual'::user_login_type) AND (password_hash IS NOT NULL) AND (external_id IS NULL)) OR
        ((login_type <> 'manual'::user_login_type) AND (password_hash IS NULL) AND (external_id IS NOT NULL))
    ),
    foreign key (current_data_provider_id) references data_providers(id) on delete set null
);

create table if not exists data_sources (
    id uuid default gen_random_uuid() not null,
    name varchar(255) not null,
    data_provider_id uuid not null,
    data_source_type_id uuid not null,
    component_id uuid not null,
    client_id varchar(255) not null,
    client_secret_hash text not null,
    created_at timestamp with time zone default now() not null,
    primary key (id),
    foreign key (data_provider_id) references data_providers(id) on delete restrict,
    foreign key (data_source_type_id) references data_source_types(id) on delete restrict,
    foreign key (component_id) references components(id) on delete restrict
);

create table if not exists data_source_aggregations (
    data_source_id uuid not null,
    aggregation_type_id uuid not null,
    created_at timestamp with time zone default now() not null,
    primary key (data_source_id, aggregation_type_id),
    foreign key (data_source_id) references data_sources(id) on delete cascade,
    foreign key (aggregation_type_id) references aggregation_types(id) on delete restrict
);
create index if not exists data_source_aggregations_aggregation_type_id_idx on data_source_aggregations (aggregation_type_id);

create table if not exists data_provider_users (
    user_id uuid not null,
    data_provider_id uuid not null,
    role provider_role not null,
    created_at timestamp with time zone default now() not null,
    primary key (user_id, data_provider_id),
    foreign key (user_id) references users(id) on delete restrict,
    foreign key (data_provider_id) references data_providers(id) on delete cascade
);

-- 4. Views
CREATE OR REPLACE VIEW data_source_aggregations_view AS
SELECT
  dsa.data_source_id AS data_source_id,   -- now a text column
  MAX(CASE WHEN at.name = 'Hour' THEN 1 ELSE 0 END)::smallint AS agg_hour,
  MAX(CASE WHEN at.name = 'Day'  THEN 1 ELSE 0 END)::smallint AS agg_day,
  MAX(CASE WHEN at.name = 'Year' THEN 1 ELSE 0 END)::smallint AS agg_year
FROM data_source_aggregations dsa
JOIN aggregation_types at ON at.id = dsa.aggregation_type_id
GROUP BY dsa.data_source_id;

