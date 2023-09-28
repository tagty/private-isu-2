deploy:
	ssh private-isu " \
		cd /home/isucon; \
		git checkout .; \
		git fetch; \
		git checkout $(BRANCH); \
		git reset --hard origin/$(BRANCH)"

build:
	ssh private-isu " \
		cd /home/isucon/private_isu/webapp/golang; \
		/home/isucon/.local/go/bin/go build -o app app.go; \
		sudo systemctl restart isu-go.service"

mysql-deploy:
	ssh private-isu "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./webapp/etc/mysql/mysql.conf.d/mysqld.cnf

mysql-rotate:
	ssh private-isu "sudo rm -f /var/log/mysql/mysql-slow.log"

mysql-restart:
	ssh private-isu "sudo systemctl restart mysql.service"

nginx-deploy:
	ssh private-isu "sudo dd of=/etc/nginx/nginx.conf" < ./webapp/etc/nginx/nginx.conf
	ssh private-isu "sudo dd of=/etc/nginx/sites-available/isucon.conf" < ./webapp/etc/nginx/sites-available/isucon.conf

nginx-rotate:
	ssh private-isu "sudo rm -f /var/log/nginx/access.log"

nginx-reload:
	ssh private-isu "sudo systemctl reload nginx.service"

nginx-restart:
	ssh private-isu "sudo systemctl restart nginx.service"

bench:
	ssh private-isu-bench " \
		/home/isucon/private_isu.git/benchmarker/bin/benchmarker -u /home/isucon/private_isu.git/benchmarker/userdata -t http://172.31.24.203"

pt-query-digest:
	ssh private-isu "sudo pt-query-digest --limit 10 /var/log/mysql/mysql-slow.log"

ALPSORT=sum
ALPM="/posts/[0-9]+,/posts?.+,/@.+,/image/[0-9]+"
OUTFORMAT=count,method,uri,min,max,sum,avg,p99

alp:
	ssh private-isu "sudo alp ltsv --file=/var/log/nginx/access.log --nosave-pos --pos /tmp/alp.pos --sort $(ALPSORT) --reverse -o $(OUTFORMAT) -m $(ALPM) -q"

pprof-kill:
	ssh private-isu "pgrep -f 'pprof' | xargs kill;"

pprof:
	go tool pprof -http=0.0.0.0:1080 -seconds=45 http://35.75.126.244/debug/pprof/profile
