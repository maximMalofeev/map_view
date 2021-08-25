import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
  id: root

  property int currentMapLayer: 10
  property var mapLayers: ({})

  onCurrentMapLayerChanged: {
    updateMap()
  }

  function setLayerItem(i, l, x, y) {
    if (!mapLayers[l]) {
      mapLayers[l] = {}
    }

    if (!mapLayers[l][x]) {
      mapLayers[l][x] = {}
    }

    mapLayers[l][x][y] = i
  }

  function hasLayerItem(l, x, y) {
    if (mapLayers[l] && mapLayers[l][x] && mapLayers[l][x][y]) {
      return true
    }
    return false
  }

  function updateMap(initialCenter) {
    let center = initialCenter ? initialCenter : Qt.point((flickable.contentX + flickable.width / 2) / background.width, (flickable.contentY + flickable.height / 2) / background.height)
    let sideLen = Math.pow(2, currentMapLayer) * Math.max(root.width, root.height)
    let contentX = Math.max(center.x * sideLen - flickable.width / 2, 0)
    let contentY = Math.max(center.y * sideLen - flickable.height / 2, 0)

    flickable.contentX = contentX
    flickable.contentY = contentY
    background.width = sideLen
    background.height = sideLen

    let count = Math.pow(2, currentMapLayer)
    let firstXTile = Math.floor(contentX / (sideLen / count))
    let lastXTile = Math.ceil((contentX + flickable.width) / (sideLen / count))
    let firstYTile = Math.floor(contentY / (sideLen / count))
    let lastYTile = Math.ceil((contentY + flickable.height) / (sideLen / count))
    for (let i = firstXTile; i < lastXTile; i++) {
      for (let j = firstYTile; j < lastYTile; j++) {
        if (hasLayerItem(currentMapLayer, i, j)) {
          continue
        }

        let tile = tileComponent.createObject(background, { mapLayer: currentMapLayer, xPos: i, yPos: j })
        setLayerItem(tile, currentMapLayer, i, j)
      }
    }

    clearCache()
  }

  function clearCache() {
    Object.keys(mapLayers).forEach(function(l) {
      l = Number(l)
      if (l !== currentMapLayer && l !== (currentMapLayer - 1) && l !== (currentMapLayer + 1) && l !== 0) {
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
    value: root.currentMapLayer
    editable: true

    onValueChanged: {
      root.currentMapLayer = value
    }
  }

  Component {
    id: tileComponent

    Image {
      id: tile
      property int mapLayer
      property int xPos
      property int yPos

      width: parent.width / Math.pow(2, mapLayer)
      height: parent.height / Math.pow(2, mapLayer)
      x: width * xPos
      y: height * yPos

      z: mapLayer
      opacity: (mapLayer <= root.currentMapLayer && progress === 1.0) ? 1.0 : 0.0
      source: "http://a.tile.stamen.com/toner/%1/%2/%3.png".arg(mapLayer).arg(xPos).arg(yPos)
//      source: "http://172.21.100.146:8008/%1/%2/%3.png".arg(mapLayer).arg(xPos).arg(yPos)

      Behavior on opacity {
        NumberAnimation { duration: 500 }
      }
    }
  }

  Component.onCompleted: {
    let tile = tileComponent.createObject(background, { mapLayer: 0, xPos: 0, yPos: 0})
    setLayerItem(tile, 0, 0, 0)
    updateMap(Qt.point(lon2relCoord(37.617617, currentMapLayer), lat2relCoord(55.755811, currentMapLayer)))
  }
}
