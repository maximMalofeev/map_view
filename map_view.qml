import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
  id: root

  property url tileServer: "http://a.tile.stamen.com/toner"
  property int zoom: 0
  property double centerLattitude: 0
  property double centerLongitude: 0
  property var mapLayers: ({})

  onZoomChanged: {
    updateMap()
  }

  function setTile(i, l, x, y) {
    if (!mapLayers[l]) {
      mapLayers[l] = {}
    }

    if (!mapLayers[l][x]) {
      mapLayers[l][x] = {}
    }

    mapLayers[l][x][y] = i
  }

  function hasTile(l, x, y) {
    if (mapLayers[l] && mapLayers[l][x] && mapLayers[l][x][y]) {
      return true
    }
    return false
  }

  function updateMap(initialCenter) {
    let center = initialCenter ? initialCenter : Qt.point((flickable.contentX + flickable.width / 2) / background.width, (flickable.contentY + flickable.height / 2) / background.height)
    let sideLen = Math.pow(2, zoom) * Math.max(root.width, root.height)
    let contentX = Math.max(center.x * sideLen - flickable.width / 2, 0)
    let contentY = Math.max(center.y * sideLen - flickable.height / 2, 0)

    flickable.contentX = contentX
    flickable.contentY = contentY
    background.width = sideLen
    background.height = sideLen

    let count = Math.pow(2, zoom)
    let firstXTile = Math.max(Math.floor(contentX / (sideLen / count)) - 1, 0)
    let lastXTile = Math.min(Math.ceil((contentX + flickable.width) / (sideLen / count)) + 1, count)
    let firstYTile = Math.max(Math.floor(contentY / (sideLen / count)) - 1, 0)
    let lastYTile = Math.min(Math.ceil((contentY + flickable.height) / (sideLen / count)) + 1, count)
    for (let i = firstXTile; i < lastXTile; i++) {
      for (let j = firstYTile; j < lastYTile; j++) {
        if (hasTile(zoom, i, j)) {
          continue
        }

        let tile = tileComponent.createObject(background, { zoom: zoom, xPos: i, yPos: j })
        setTile(tile, zoom, i, j)
      }
    }

    clearCache()
  }

  function clearCache() {
    // remove layers
    Object.keys(mapLayers).forEach(function(l) {
      l = Number(l)
      if (l !== zoom && l !== (zoom - 1) && l !== (zoom + 1) && l !== 0) {
        Object.keys(mapLayers[l]).forEach(function(x) {
          Object.keys(mapLayers[l][x]).forEach(function(y) {
            mapLayers[l][x][y].destroy()
            delete mapLayers[l][x][y]
          })
          delete mapLayers[l][x]
        })
        delete mapLayers[l]
      }
    })
  }

  function lon2relCoord(lon) {
    return (lon + 180) / 360
  }
  function lat2relCoord(lat) {
    return (1 - Math.log(Math.tan(lat * Math.PI / 180) + 1 / Math.cos(lat * Math.PI / 180)) / Math.PI) / 2
  }

  width: 800
  height: 600
  visible: true

  Flickable {
    id: flickable
    anchors.fill: parent
    clip: true
    contentWidth: background.width
    contentHeight: background.height

    onMovementEnded: {
      root.updateMap()
    }

    Behavior on contentX {
      NumberAnimation { duration: 1000 }
    }
    Behavior on contentY {
      NumberAnimation { duration: 1000 }
    }

    Rectangle {
      id: background
      color: "gray"
      width: Math.max(root.width, root.height)
      height: Math.max(root.width, root.height)

      Behavior on width {
        NumberAnimation { duration: 1000 }
      }
      Behavior on height {
        NumberAnimation { duration: 1000 }
      }
    }
  }

  SpinBox {
    id: zoomSlider
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.margins: 5
    from: 0
    to: 100
    stepSize: 1
    value: root.zoom
    editable: true

    onValueChanged: {
      root.zoom = value
    }
  }

  Component {
    id: tileComponent

    Image {
      id: tile
      property int zoom
      property int xPos
      property int yPos

      width: parent.width / Math.pow(2, zoom)
      height: parent.height / Math.pow(2, zoom)
      x: width * xPos
      y: height * yPos

      z: zoom
      opacity: (zoom <= root.zoom && progress === 1.0) ? 1.0 : 0.0
      source: root.tileServer + "/%1/%2/%3.png".arg(zoom).arg(xPos).arg(yPos)

      Behavior on opacity {
        NumberAnimation { duration: 500 }
      }
    }
  }

  Component.onCompleted: {
    let tile = tileComponent.createObject(background, { zoom: 0, xPos: 0, yPos: 0})
    setTile(tile, 0, 0, 0)
    updateMap(Qt.point(lon2relCoord(centerLattitude, zoom), lat2relCoord(centerLongitude, zoom)))
    //    updateMap(Qt.point(lon2relCoord(37.617617, zoom), lat2relCoord(55.755811, zoom)))
  }
}
