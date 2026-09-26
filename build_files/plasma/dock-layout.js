// Iceberg desktop layout: a floating dock of apps at the bottom, and a floating
// status pill (quick settings, notifications, clock) in the top-right corner.
// build.sh fills in the pinned apps and the tile style (dock-style.json) when the image is built.

// Panel Colorizer draws the rounded panel and, optionally, a tile behind each widget.
// It stays hidden and only applies the style.
function addPanelStyle(panel, widgetTiles) {
    var settings = @DOCK_STYLE@;
    if (!widgetTiles) {
        settings.widgets.normal.backgroundColor.enabled = false;
        settings.widgets.normal.border.enabled = false;
    }
    var style = panel.addWidget("luisbocanegra.panel.colorizer");
    style.currentConfigGroup = ["General"];
    style.writeConfig("hideWidget", true);
    style.writeConfig("globalSettings", JSON.stringify(settings));
}

var dock = new Panel;
dock.location = "bottom";
dock.height = 2 * Math.ceil(gridUnit * 4.5 / 2);
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

// App icons already sit on their own plates, so the dock gets no extra tiles
addPanelStyle(dock, false);

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
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("fontFamily", "Inter");
clock.writeConfig("fontStyleName", "Medium");
clock.writeConfig("fontSize", 10);

addPanelStyle(status, true);

var desktops = desktopsForActivity(currentActivity());
for (var i = 0; i < desktops.length; i++) {
    desktops[i].wallpaperPlugin = "org.kde.image";
}
