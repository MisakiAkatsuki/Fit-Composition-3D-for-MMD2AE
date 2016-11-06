##########
#######
###
  Fit Composition 3D for MMD2AE
    (C) あかつきみさき(みくちぃP)

  このスクリプトについて
    このスクリプトはMMD2AEで出力した,nullで親子付けされたカメラレイヤー専用のものです.
    3Dレイヤーをアクティブカメラを使用して,コンポジションサイズにフィットするようにリサイズします.

  使用方法
    1.ファイル→スクリプト→スクリプトファイルの実行から実行.

  動作環境
    Adobe After Effects CS6以上

  ライセンス
    MIT License

  バージョン情報
    2016/11/07 Ver 1.2.0 Update
      対応バージョンの変更.

    2014/02/17 Ver 1.1.0 Update
      方向がずれていた問題の修正.

    2014/01/06 Ver 1.0.0 Release
###
######
#########

FC3D4MMD2AEData = ( ->
  scriptName          = "Fit Composition 3D for MMD2AE"
  scriptURLName       = "FitComposition3DforMMD2AE"
  scriptVersionNumber = "1.2.0"
  scriptURLVersion    = 120
  canRunVersionNum    = 11.0
  canRunVersionC      = "CS6"

  return{
    getScriptName         : -> scriptName
    getScriptURLName      : -> scriptURLName
    getScriptVersionNumber: -> scriptVersionNumber
    getCanRunVersionNum   : -> canRunVersionNum
    getCanRunVersionC     : -> canRunVersionC
    getGuid               : -> guid
   }
)()

ADBE_TRANSFORM_GROUP  = "ADBE Transform Group"
ADBE_POSITION         = "ADBE Position"
ADBE_SCALE            = "ADBE Scale"
ADBE_ORIENTATION      = "ADBE Orientation"

CAMERA_NAME  = "MMD CAMERA"
parentNullX  = CAMERA_NAME + " CONTROL X"
parentNullY = CAMERA_NAME + " CONTROL Y"

# 対象の名前のレイヤーが存在するか確認する
CompItem::hasTargetLayer = (targetName) ->
  return @layer(targetName)?

###
起動しているAEの言語チェック
###
getLocalizedText = (str) ->
  if app.language is Language.JAPANESE
    str.jp
  else
    str.en

###
許容バージョンを渡し,実行できるか判別
###
runAEVersionCheck = (AEVersion) ->
  if parseFloat(app.version) < AEVersion.getCanRunVersionNum()
    alert "This script requires After Effects #{AEVersion.getCanRunVersionC()} or greater."
    return false
  else
    return true

###
コンポジションにアクティブカメラが存在するか確認する関数
###
hasActiveCamera = (actComp) ->
  return actComp.activeCamera?

###
コンポジションを選択しているか確認する関数
###
isCompActive = (selComp) ->
  unless(selComp and selComp instanceof CompItem)
    alert "Select Composition"
    return false
  else
    return true

###
レイヤーを選択しているか確認する関数
###
isLayerSelected = (selLayers) ->
  if selLayers.length is 0
    alert "Select Layers"
    return false
  else
    return true


entryFunc = () ->
# -------------------------------------------------------------------------
  # アクティブカメラが存在しない場合,カメラを追加する.
  unless hasActiveCamera actComp
    actComp.layers.addCamera(FC3D4MMD2AEData.getScriptName(), [actComp.width/2, actComp.height/2])

  unless actComp.hasTargetLayer(CAMERA_NAME)
    CAMERA_NAME = prompt "MMD camera not found\nPut MMD camera layer's name", CAMERA_NAME
    parentNullX = CAMERA_NAME + " CONTROL X"
    parentNullY = CAMERA_NAME + " CONTROL Y"

  return 0 unless CAMERA_NAME?
  return 0 unless actComp.hasTargetLayer(CAMERA_NAME)

  unless actComp.hasTargetLayer(parentNullX)
    parentNullX = prompt "Control X not found\nPut Control X layer's name", parentNullX

  return 0 unless parentNullX?
  return 0 unless actComp.hasTargetLayer(parentNullX)

  unless actComp.hasTargetLayer(parentNullY)
    parentNullY = prompt "Control Y not found\nPut Control Y layer's name", CAMERA_NAME

  return 0 unless parentNullY?
  return 0 unless actComp.hasTargetLayer(parentNullY)

# -------------------------------------------------------------------------

  for curLayer in [0...selLayers.length] by 1
    # 対象のレイヤーがカメラかライトの場合は除外する
    continue if selLayers[curLayer] instanceof CameraLayer or selLayers[curLayer] instanceof LightLayer

    selLayers[curLayer].threeDLayer = true

    selLayers[curLayer].property(ADBE_TRANSFORM_GROUP).property(ADBE_POSITION).expression =
      "thisComp.layer(\"#{CAMERA_NAME} CONTROL Y\").transform.position;"

    selLayers[curLayer].property(ADBE_TRANSFORM_GROUP).property(ADBE_SCALE).expression =
      """
      var actCam = thisComp.activeCamera;
      var camPointOfInterest = thisComp.layer("#{CAMERA_NAME} CONTROL X").transform.anchorPoint;
      var camPosition = actCam.transform.position;
      var camZoom = actCam.cameraOption.zoom;

      var x = Math.abs(camPointOfInterest[0] - camPosition[0]);
      var y = Math.abs(camPointOfInterest[1] - camPosition[1]);
      var z = Math.abs(camPointOfInterest[2] - camPosition[2]);

      range = Math.sqrt((x*x + y*y + z*z));
      thisScale = range / camZoom * 100;

      [thisScale, thisScale, thisScale]
      """

    selLayers[curLayer].property(ADBE_TRANSFORM_GROUP).property(ADBE_ORIENTATION).expression =
      """
      var x = transform.orientation[0];
      var y = transform.orientation[1];
      var z = transform.orientation[2] + thisComp.layer(\"#{CAMERA_NAME} CONTROL X\").transform.zRotation;

      [x, y, z]
      """

    selLayers[curLayer].autoOrient = AutoOrientType.CAMERA_OR_POINT_OF_INTEREST
  return 0

undoEntryFunc = (data) ->
  app.beginUndoGroup data.getScriptName()
  entryFunc()
  app.endUndoGroup()
  return 0

###
メイン処理開始
###
return 0 unless runAEVersionCheck FC3D4MMD2AEData

actComp = app.project.activeItem
return 0 unless isCompActive actComp

selLayers = actComp.selectedLayers
return 0 unless isLayerSelected selLayers

undoEntryFunc FC3D4MMD2AEData
return 0
