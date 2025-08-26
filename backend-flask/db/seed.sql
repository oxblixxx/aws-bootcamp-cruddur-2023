-- Insert users with required email field
INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown', 'andrew@example.com', 'MOCK'),
  ('Andrew Bayko', 'bayko', 'bayko@example.com', 'MOCK');

-- Insert activity linked to Andrew Brown
INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid FROM public.users WHERE handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  );
