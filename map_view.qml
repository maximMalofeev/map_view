import QtQuick 2.15
import QtQuick.Controls 2.15

ApplicationWindow {
  id: root

  property int currentMapLayer: zoomSlider.value
  property var mapLayers: ({})

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

  function updateMap() {
    let count = Math.pow(2, currentMapLayer)
    let firstXTile = Math.floor(flickable.contentX / (background.width / count))
    let lastXTile = Math.ceil((flickable.contentX + flickable.width) / (background.width / count))
    let firstYTile = Math.floor(flickable.contentY / (background.height / count))
    let lastYTile = Math.ceil((flickable.contentY + flickable.height) / (background.height / count))
    for (let i = firstXTile; i < lastXTile; i++) {
      for (let j = firstYTile; j < lastYTile; j++) {
        if (hasLayerItem(currentMapLayer, i, j)) {
          continue
        }

        let tile = tileComponent.createObject(background, {
                                                mapLayer: currentMapLayer,
                                                xPos: i,
                                                yPos: j,
                                              })
        setLayerItem(tile, currentMapLayer, i, j)
      }
    }
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

  Slider {
    id: zoomSlider
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 5
    from: 0
    to: 100
    stepSize: 1

    onValueChanged: {
      if (value != root.currentMapLayer) {
        root.currentMapLayer = value
        let center = Qt.point((flickable.contentX + flickable.width / 2) / background.width, (flickable.contentY + flickable.height / 2) / background.height)
        let newSideLen = Math.pow(2, value) * Math.max(root.width, root.height)

        flickable.contentX = center.x * newSideLen - flickable.width / 2
        flickable.contentY = center.y * newSideLen - flickable.height / 2
        background.width = newSideLen
        background.height = newSideLen

        updateMap()
      }
    }
  }

  Component {
    id: tileComponent

    Image {
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

      Behavior on opacity {
        NumberAnimation { duration: 500 }
      }
    }
  }

  Component.onCompleted: {
    let tile = tileComponent.createObject(background, { mapLayer: root.currentMapLayer, xPos: 0, yPos: 0})
    setLayerItem(tile, currentMapLayer, 0, 0)
  }
}
