# Generation of the iso file.
#set :mkisotool, "genisoimage -RJ -o"
# mac
set :mkisotool, "hdiutil makehybrid -joliet -iso -ov -o "

# Snooze specifics
# snooze version to installed
set :snooze_version, "2.1.5"
# config file version to use
set :version, 2
# deprecated
set :vlan, "-1"

# where to find the deb packages
#set :snoozenode_deb_url, "http://snooze.inria.fr/downloads/debian/#{snooze_version}/snoozenode.deb"
set :snoozenode_deb_url, "https://ci.inria.fr/snooze-software/view/maint/job/maint-2.1.0-snoozenode/ws/distributions/deb-package/snoozenode_2.1.6-0_all.deb"
set :snoozeclient_deb_url, "http://snooze.inria.fr/downloads/debian/#{snooze_version}/snoozeclient.deb"
set :snoozeimages_deb_url, "http://snooze.inria.fr/downloads/debian/#{snooze_version}/snoozeimages.deb"
set :snoozeec2_deb_url, "http://snooze.inria.fr/downloads/debian/#{snooze_version}/snoozeec2.deb"

# kadeploy 
set :kadeploy3_common_deb_url, "https://gforge.inria.fr/frs/download.php/33640/kadeploy-common_3.2.0.7-1_all.deb"
set :kadeploy3_client_deb_url, "https://gforge.inria.fr/frs/download.php/33639/kadeploy-client_3.2.0.7-1_all.deb"

# web interface
set :webinterface_directory, "/tmp/snoozeweb"
set :webinterface_url, "https://github.com/msimonin/snoozeweb.git"
