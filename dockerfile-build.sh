docker build -t backend-flask ./backend-flask 
docker run --rm -p 4567:4567 -it backend-flask
docker run --rm -p 4567:4567 -it -e FRONTEND_URL -e BACKEND_URL backend-flask
docker run --rm -p 4567:4567 --it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask

# this logs in the db on your localmachine
psql --host localhost
psql -Upostgres --host localhost