# Generation of the iso file.
#set :mkisotool, "genisoimage -RJ -o"
# mac
set :mkisotool, "hdiutil makehybrid -joliet -iso -ov -o "

# Snooze specifics
set :version, 2
set :vlan, "-1"
set :snoozenode_deb_url, "http://snooze.inria.fr/downloads/debian/latest/snoozenode.deb"
set :snoozeclient_deb_url, "http://snooze.inria.fr/downloads/debian/latest/snoozeclient.deb"
set :snoozeimages_deb_url, "http://snooze.inria.fr/downloads/debian/latest/snoozeimages.deb"
set :snoozeec2_deb_url, "http://snooze.inria.fr/downloads/debian/latest/snoozeec2.deb"

set :kadeploy3_common_deb_url, "https://gforge.inria.fr/frs/download.php/33640/kadeploy-common_3.2.0.7-1_all.deb"
set :kadeploy3_client_deb_url, "https://gforge.inria.fr/frs/download.php/33639/kadeploy-client_3.2.0.7-1_all.deb"

# web interface
set :webinterface_directory, "/tmp/snoozeweb"
set :webinterface_url, "https://github.com/msimonin/snoozeweb.git"
