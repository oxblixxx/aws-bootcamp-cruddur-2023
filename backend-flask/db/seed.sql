-- this file was manually created, replace the values with corresponding one from AWS COGNITO USER POOL FROM WEEK 4
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES  
  ('Pelumi Mustapha','phamust1111@gmail.com' , 'oxblixxxx' ,'MOCK'),
  ('Londo Mollari', 'lmollari@centari.com','londo','MOCK'),
  ('Lundi Madu','torontoqw1@gmail.com' , 'toronto' ,'MOCK'),
  ('Pelumi Mustapha','oxblixxx@gmail.com' , 'bigtade' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
-- replace with users.handle name with the primary user you'd need to login with
  (
    (SELECT uuid from public.users WHERE users.handle = 'oxblixxxx' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )