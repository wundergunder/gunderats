/*
  # Create admin company and association

  1. Changes
    - Creates a company record for the admin user
    - Associates the admin user with the company via team_members
    - Creates default pipeline stages for the company

  2. Security
    - No changes to RLS policies
*/

-- Create company for admin
INSERT INTO companies (name, subscription_status)
VALUES ('Test Company', 'active')
ON CONFLICT DO NOTHING;

-- Associate admin user with company
WITH company_id AS (
  SELECT id FROM companies WHERE name = 'Test Company' LIMIT 1
),
user_id AS (
  SELECT id FROM auth.users WHERE email = 'work@test.com' LIMIT 1
)
INSERT INTO team_members (user_id, company_id, role)
SELECT user_id.id, company_id.id, 'admin'
FROM user_id, company_id
ON CONFLICT DO NOTHING;

-- Create default pipeline stages
WITH company_id AS (
  SELECT id FROM companies WHERE name = 'Test Company' LIMIT 1
)
INSERT INTO pipeline_stages (company_id, name, order_index)
SELECT 
  company_id.id,
  stage_name,
  stage_index
FROM 
  company_id,
  (VALUES 
    ('Applied', 0),
    ('Screening', 1),
    ('Interview', 2),
    ('Offer', 3),
    ('Hired', 4)
  ) AS stages(stage_name, stage_index)
ON CONFLICT DO NOTHING;