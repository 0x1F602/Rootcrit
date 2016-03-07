echo "You have to have carton installed";
carton install
carton exec perl motion.pl
read -p "You must edit rootcrit.conf. Hit any key to continue." -n 1
vim rootcrit.conf
echo "Run rootcrit with 'carton exec perl rootcrit.pl daemon'"
