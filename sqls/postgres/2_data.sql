-- COMPONENTS
INSERT INTO components (id, name, description, created_at) VALUES ('ef3c5da9-0413-4ae6-a6ff-1de74eecb733', 'PM10', 'Particulate matter with diameter ≤ 10 micrometers', '2025-07-17 10:59:17.426183 +00:00');
INSERT INTO components (id, name, description, created_at) VALUES ('1757af25-2509-4577-8f21-83852a756bdf', 'PM2.5', 'Particulate matter with diameter ≤ 2.5 micrometers', '2025-07-17 10:59:17.426183 +00:00');
INSERT INTO components (id, name, description, created_at) VALUES ('878a5125-1973-4595-8323-34ded63f3326', 'NO', 'Nitric oxide', '2025-07-17 10:59:17.426183 +00:00');
INSERT INTO components (id, name, description, created_at) VALUES ('4293c727-ae29-40e1-b9d7-f40fa9707859', 'NO2', 'Nitrogen dioxide', '2025-07-17 10:59:17.426183 +00:00');
INSERT INTO components (id, name, description, created_at) VALUES ('49290265-ae8a-4bb3-b166-ca425910d80c', 'NOX', 'Nitrogen oxides (NO and NO2 collectively)', '2025-07-17 10:59:17.426183 +00:00');
INSERT INTO components (id, name, description, created_at) VALUES ('5502dc9c-a702-4272-9c27-36b866778ff4', 'CO', 'Carbon monoxide', '2025-07-17 10:59:17.426183 +00:00');
INSERT INTO components (id, name, description, created_at) VALUES ('fbe75079-19a7-426c-abaa-5ff89c9f5aa1', 'SO2', 'Sulfur dioxide', '2025-07-17 10:59:17.426183 +00:00');
INSERT INTO components (id, name, description, created_at) VALUES ('c414c182-4c21-4193-94f8-0d19f66a3386', 'O3', 'Ozone', '2025-07-17 10:59:17.426183 +00:00');

-- AGGREGATION TYPES
INSERT INTO aggregation_types (id, name, description, created_at) VALUES ('662ca20c-ba3e-4c63-8e2b-d54e91aad7f3', 'Hour', 'Aggregate by hour', '2025-07-17 10:59:17.423978 +00:00');
INSERT INTO aggregation_types (id, name, description, created_at) VALUES ('bfd97744-7945-43cf-b9fd-6863c59d4e4a', 'Day', 'Aggregate by day', '2025-07-17 10:59:17.423978 +00:00');
INSERT INTO aggregation_types (id, name, description, created_at) VALUES ('96dbbae5-e2ba-460e-af13-430b74b636ba', 'Year', 'Aggregate by year', '2025-07-17 10:59:17.423978 +00:00');

-- ADIM USER
INSERT INTO public.users (id, email, first_name, last_name, login_type, external_id, password_hash, is_admin, is_verified, current_data_provider_id, created_at) VALUES ('0e56d5ee-e404-4216-b891-cf241281cc4e', 'admin@example.com', 'Admin', 'User', 'manual', null, '$2b$12$k5Q1ogfLB8C7gaJABurYlezVFR2YD3CsF.qZ7t0bYsWTpATFVbrwi', true, true, 'ed6fd95c-b5af-40e0-afe6-bc514c487aa1', '2025-07-17 10:59:17.418523 +00:00');
