// Iceberg desktop layout: a floating dock of apps at the bottom, and a floating
// status pill (quick settings, notifications, clock) in the top-right corner.
// build.sh fills in the pinned apps and the tile style (dock-style.json) when the image is built.

// Panel Colorizer draws the rounded tiles. It stays hidden and only applies the style.
function addTileStyle(panel) {
    var style = panel.addWidget("luisbocanegra.panel.colorizer");
    style.currentConfigGroup = ["General"];
    style.writeConfig("hideWidget", true);
    style.writeConfig("globalSettings", JSON.stringify(@DOCK_STYLE@));
}

var dock = new Panel;
dock.location = "bottom";
dock.height = 2 * Math.ceil(gridUnit * 3.5 / 2);
dock.lengthMode = "fit";
dock.alignment = "center";
dock.floating = true;
dock.hiding = "none";

var launcher = dock.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "iceberg-logo");

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", @LAUNCHERS@);

addTileStyle(dock);

var status = new Panel;
status.location = "top";
status.height = 2 * Math.ceil(gridUnit * 2.25 / 2);
status.lengthMode = "fit";
status.alignment = "right";
status.floating = true;
status.hiding = "none";

status.addWidget("org.kde.plasma.systemtray");

var clock = status.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd d MMM");
clock.writeConfig("dateDisplayFormat", 1); // beside the time

addTileStyle(status);

var desktops = desktopsForActivity(currentActivity());
for (var i = 0; i < desktops.length; i++) {
    desktops[i].wallpaperPlugin = "org.kde.image";
}
