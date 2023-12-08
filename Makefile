.PHONY : build destroy rebuild rebuild-db

build:
	vagrant up

destroy:
	vagrant destroy -f

rebuild: destroy build
rebuild-db:
	vagrant destroy database-01 database-02 -f
	$(MAKE) build