-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES  
  ('Pelumi Mustapha','phamust1111@gmail.com' , 'oxblixxxx' ,'MOCK'),
  ('Londo Mollari', 'lmollari@centari.com','londo','MOCK'),
  ('Lundi Madu','torontoqw1@gmail.com' , 'toronto' ,'MOCK'),
  ('Pelumi Mustapha','oxblixxx@gmail.com' , 'bigtade' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'oxblixxxx' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )