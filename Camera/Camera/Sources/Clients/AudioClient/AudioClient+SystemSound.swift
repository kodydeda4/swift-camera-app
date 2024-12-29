import Foundation

extension AudioClient {
  enum SystemSound: Int {
    case newMail = 1000
    case mailSent = 1001
    case voicemail = 1002
    case receivedMessage = 1003
    case sentMessage = 1004
    case calendarAlert = 1005
    case lowPower = 1006
    case smsReceived1 = 1007
    case smsReceived2 = 1008
    case smsReceived3 = 1009
    case smsReceived4 = 1010
    case smsReceivedVibrate = 1011
    case tweetSent = 1016
    case anticipate = 1020
    case bloom = 1021
    case calypso = 1022
    case chooChoo = 1023
    case descent = 1024
    case fanfare = 1025
    case ladder = 1026
    case minuet = 1027
    case newsFlash = 1028
    case noir = 1029
    case sherwoodForest = 1030
    case spell = 1031
    case suspense = 1032
    case telegraph = 1033
    case tiptoes = 1034
    case typewriters = 1035
    case update = 1036
    case lock = 1100
    case unlock = 1101
    case keyPressedTink = 1103
    case keyPressedTock = 1104
    case cameraShutter = 1108
    case shakeToShuffle = 1109
    case beginRecording = 1113
    case endRecording = 1114
    case beginVideoRecording = 1117
    case endVideoRecording = 1118
    case connectedToPower = 1106
    case vibrate = 4095
  }
}
