#!/bin/bash
mkdir s3Volume
sudo apt update
sudo apt install s3fs -y
sudo apt install openjdk-11-jre -y
sudo apt install nginx -y  
sudo systemctl enable nginx  
sudo systemctl enable nginx 

##############################################
#Checking nginx intalled or not

   #    if [ ! -x /usr/sbin/nginx ] 
#then
 #       echo "Nginx is not installed."
  #              then exit
   #     elif [ -x /usr/sbin/nginx ]
 #then
  #              echo "Nginx is already installed."
   #             echo "Restarting Nginx..."
    #            systemctl enable nginx.service
     #           systemctl restart nginx.service
      #          echo "Done."
       # fi

#################################################
#Checking nginx service status

#nginxStatus=$(systemctl show nginx.service \
 #       --property=ActiveState | cut -d "=" -f 2)
  #      if [ $nginxStatus = active ]
 #then
   #             echo "Nginx is active and running."
  #      elif [ $nginxStatus = inactive ]
 #then
  #              echo "Nginx is not running."
   #             echo "Starting Nginx..."
    #            systemctl start nginx.service
     #   else
      #          echo "Something went wrong nginx status: $nginxStatus"
       # fi

#echo 'user_allow_other' >> etc/fuse.conf


sudo s3fs zaq11qaz s3Volume/ -o allow_other -o use_path_request_style -o passwd_file=/home/ubuntu/.passwd-s3fs -o nonempty -o rw -o mp_umask=002 -o uid=1000 -o gid=1000

sleep 10
###################################################
#sudo s3fs /home/ubuntu/s3Volume/ \-o allow_other \
#-o use_path_request_style \
#-o passwd_file=/home/ubuntu/.passwd-s3fs \
#-o nonempty -o rw\
#-o mp_umask=002 -o uid=1000 -o gid=1000
#######################################
#Configures Nginx to use custom configuration

        echo "Configuring Nginx..."
        echo -e 'server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /home/ubuntu/s3Volume;
                index index.html;
        server_name _;
        location / {
                try_files $uri $uri/ =403;
        }' > /home/ubuntu/s3Volume/nginx.conf

#################################################
sudo rm -f /var/www/html/*
. /home/ubuntu/s3Volume/refresh.sh  && \
sudo mv home/ubuntu/s3Volume/index.html /var/www/html/
################################################
sudo chmod 666 /home/ubuntu/s3Volume/nginx.conf
sudo chmod 777 /home/ubuntu/s3Volume/refresh.sh
################################################
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default
sudo cp /home/ubuntu/s3Volume/nginx.conf /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/nginx.conf /etc/nginx/sites-enabled/default
################################################
##############################################
#meking start service

sudo systemctl reload -s nginx

#sudo mv revresh.sh /usr/bin/
start_service () {
	sudo systemctl daemon-reload && \
sudo systemctl enable refresh.service &&  \
sudo systemctl start refresh.service
}

echo -e "[Unit]\nDescription=Refresh file\n\n[Service]\nExecStart=/home/ubuntu/s3Volume/refresh.sh\nRestart=always\n\n[Install]\nWantedBy=multi-user.target" > /home/ubuntu/refresh.service



if [[ ! -f /lib/systemd/system/refresh.service ]]
then
	sudo mv /home/ubuntu/refresh.service /lib/systemd/system/ && \ start_service
	#sudo systemctl daemon-reload
	#sudo systemctl start update_page && \
	echo "Update page service started."
elif [[ $(cat /home/ubuntu/refresh.service) = $(cat /lib/systemd/system/refresh.service) ]]

then start_service

else sudo rm -f /lib/systemd/system/refresh.service && \
sudo mv /home/ubuntu/refresh.service /lib/systemd/system/ && \ start_service
fi


sudo systemctl restart nginx.service







# echo -e "[Unit]\nDescription=Refresh\n\n[Service]\nExecStart=/home/ubuntu/refresh.sh\nRestart=always\n\n[Install]\nWantedBy=multi-user.target" > /home/ubuntu/refresh.service

##########################################################################
#cheking service status

#if [[ ! -f /lib/systemd/system/refresh.service ]]
#then
#sudo mv /home/ubuntu/refresh.service /lib/systemd/system/ && \
#start_service
#elif [[ $(cat /home/ubuntu/refresh.service) = $(cat /lib/systemd/system/refresh.service) ]]
#then
#start_service
#else
#sudo rm -f /lib/systemd/system/refresh.service && \
#sudo mv /home/ubuntu/refresh.service /lib/systemd/system/ && \
#start_service
#fi















