import AVFoundation
import Combine
import Dependencies
import Photos
import Sharing
import SwiftUI

@MainActor
@Observable
final class CountdownModel: Identifiable {
  let id = UUID()
  var secondsElapsed = 0
  var onFinish: () -> Void
    = unimplemented("RecordingCountdownModel.onFinish")
  
  @ObservationIgnored @Dependency(\.continuousClock) var clock
  @ObservationIgnored @SharedReader(.userSettings) var userSettings
  
  var countdown: Int {
    self.userSettings.countdownTimer - self.secondsElapsed
  }
  
  private var isTimerFinished: Bool {
    self.secondsElapsed >= self.userSettings.countdownTimer - 1
  }

  func task() async {
    await withTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        for await _ in await self.clock.timer(interval: .seconds(1)) {
          await MainActor.run {
            
            guard !self.isTimerFinished else {
              self.onFinish()
              return
            }
            
            self.secondsElapsed += 1
          }
        }
      }
    }
  }
}

// MARK: - SwiftUI

struct CountdownView: View {
  @Bindable var model: CountdownModel
  
  var body: some View {
    Text(self.model.countdown.description)
      .font(.largeTitle)
      .fontWeight(.bold)
      .task { await self.model.task() }
  }
}

// MARK: - SwiftUI Previews

//@DEDA fix this preview
#Preview("Settings") {
  CountdownView(model: CountdownModel())
}
