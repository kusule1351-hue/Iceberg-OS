// Iceberg desktop layout: one floating, centred dock made of rounded tiles.
// build.sh fills in the pinned apps and the tile style (dock-style.json) when the image is built.

var panel = new Panel;
panel.location = "bottom";
panel.height = 2 * Math.ceil(gridUnit * 3.5 / 2);
panel.lengthMode = "fit";
panel.alignment = "center";
panel.floating = true;
panel.hiding = "none";

var launcher = panel.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "iceberg-logo");

var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", @LAUNCHERS@);

panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");

// Panel Colorizer draws the tiles. It stays hidden and only applies the style.
var style = panel.addWidget("luisbocanegra.panel.colorizer");
style.currentConfigGroup = ["General"];
style.writeConfig("hideWidget", true);
style.writeConfig("globalSettings", JSON.stringify(@DOCK_STYLE@));

var desktops = desktopsForActivity(currentActivity());
for (var i = 0; i < desktops.length; i++) {
    desktops[i].wallpaperPlugin = "org.kde.image";
}
