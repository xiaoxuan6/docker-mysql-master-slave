container ?= mysql-master

up:
	@docker-compose up -d --build
down:
	@docker-compose down
retry: down up
	# restart containers ok!

exec:
	@docker exec -it $(container) sh