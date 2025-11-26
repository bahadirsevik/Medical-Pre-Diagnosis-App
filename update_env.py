import os

env_path = 'backend/.env'
new_lines = []
supabase_url = 'https://hqkcuxwxdsybtxqgnydx.supabase.co'
supabase_key = 'sb_publishable_efbQ-0WZV8kPB-Jb8aOHpg_S61Al-Iw'
db_url = 'postgresql://postgres:MedicalAppPassword1234@db.hqkcuxwxdsybtxqgnydx.supabase.co:5432/postgres'

with open(env_path, 'r') as f:
    for line in f:
        if line.startswith('DATABASE_URL='):
            new_lines.append(f'DATABASE_URL={db_url}\n')
        elif line.startswith('SUPABASE_URL=') or line.startswith('SUPABASE_KEY='):
            continue # Remove if exists to avoid dupe
        else:
            new_lines.append(line)

# Add new vars
new_lines.append(f'SUPABASE_URL={supabase_url}\n')
new_lines.append(f'SUPABASE_KEY={supabase_key}\n')

with open(env_path, 'w') as f:
    f.writelines(new_lines)

print("Updated .env successfully")
