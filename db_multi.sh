#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf
cd $HOME/multipool/yiimp_multi
if [ -d "$HOME/multipool/yiimp_multi" ]; then
  cd $HOME/multipool/yiimp_multi
else
  cd $HOME
fi

echo -e " Building DB server...$COL_RESET"
echo
echo -e " Installing MariaDB 10.4...$COL_RESET"
MARIADB_VERSION='10.4'
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $DBRootPassword"
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $DBRootPassword"
apt_install mariadb-server mariadb-client

echo -e " Creating YiiMP DB...$COL_RESET"
Q1="CREATE DATABASE IF NOT EXISTS ${YiiMPDBName};"
Q2="GRANT ALL ON ${YiiMPDBName}.* TO '${YiiMPPanelName}'@'${WebInternalIP}' IDENTIFIED BY '${PanelUserDBPassword}';"
Q3="GRANT ALL ON ${YiiMPDBName}.* TO '${StratumDBUser}'@'${StratumInternalIP}' IDENTIFIED BY '${StratumUserDBPassword}';"
Q4="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}"
sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"

echo '[clienthost1]
user='"${YiiMPPanelName}"'
password='"${PanelUserDBPassword}"'
database='"${YiiMPDBName}"'
host='"${WebInternalIP}"'
[clienthost2]
user='"${StratumDBUser}"'
password='"${StratumUserDBPassword}"'
database='"${YiiMPDBName}"'
host='"${StratumInternalIP}"'
[mysql]
user=root
password='"${DBRootPassword}"'
' | sudo -E tee $STORAGE_ROOT/yiimp/.my.cnf >/dev/null 2>&1
sudo chmod 0600 $STORAGE_ROOT/yiimp/.my.cnf
echo -e "$GREEN DB users and passwords can be found in $STORAGE_ROOT/yiimp/.my.cnf$COL_RESET"

cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/sql
# import sql dump
sudo zcat 2020-11-10-yaamp.sql.gz | sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName}
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2016-04-24-market_history.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2016-04-27-settings.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2016-05-11-coins.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2016-05-15-benchmarks.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2016-05-23-bookmarks.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2016-06-01-notifications.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2016-06-04-bench_chips.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2016-11-23-coins.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2017-02-05-benchmarks.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2017-03-31-earnings_index.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2020-06-03-blocks.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2017-05-accounts_case_swaptime.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2017-06-payouts_coinid_memo.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2017-09-notifications.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2017-10-bookmarks.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2018-09-22-workers.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2017-11-segwit.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2018-01-stratums_ports.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2018-02-coins_getinfo.sql
sudo mysql -u root -p"${DBRootPassword}" ${YiiMPDBName} --force < 2019-03-coins_thepool_life.sql
sudo sed -i '/max_connections/c\max_connections         = 800' /etc/mysql/my.cnf
sudo sed -i '/thread_cache_size/c\thread_cache_size       = 512' /etc/mysql/my.cnf
sudo sed -i '/tmp_table_size/c\tmp_table_size          = 128M' /etc/mysql/my.cnf
sudo sed -i '/max_heap_table_size/c\max_heap_table_size     = 128M' /etc/mysql/my.cnf
sudo sed -i '/wait_timeout/c\wait_timeout            = 60' /etc/mysql/my.cnf
sudo sed -i '/max_allowed_packet/c\max_allowed_packet      = 64M' /etc/mysql/my.cnf
sudo sed -i 's/#bind-address=0.0.0.0/bind-address='${DBInternalIP}'/g' /etc/mysql/my.cnf
restart_service mysql;
echo -e "$GREEN DB server build completed...$COL_RESET"

cd $HOME/multipool/yiimp_multi
