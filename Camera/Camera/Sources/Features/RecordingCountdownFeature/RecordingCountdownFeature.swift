import AVFoundation
import Combine
import Dependencies
import Photos
import Sharing
import SwiftUI

@MainActor
@Observable
final class RecordingCountdownModel: Identifiable {
  let id = UUID()
  var secondsElapsed = 0
  var onFinish: () -> Void
    = unimplemented("RecordingCountdownModel.onFinish")
  @ObservationIgnored @Dependency(\.continuousClock) var clock
  @ObservationIgnored @SharedReader(.userSettings) var userSettings
  
  var countdown: Int {
    self.userSettings.countdownTimer - self.secondsElapsed
  }

  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        for await _ in await self.clock.timer(interval: .seconds(1)) {
          await MainActor.run {
            self.secondsElapsed += 1
            
            if self.countdown == 0 {
              self.onFinish()
            }
          }
        }
      }
    }
  }
}

struct RecordingCountdownView: View {
  @Bindable var model: RecordingCountdownModel
  
  var body: some View {
    Text(self.model.countdown.description)
      .font(.title)
      .fontWeight(.bold)
      .task { await self.model.task() }
  }
}

//@DEDA fix this preview
#Preview("Settings") {
  RecordingCountdownView(model: RecordingCountdownModel())
}
