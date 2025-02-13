import AVFoundation
import Combine
import Dependencies
import Photos
import Sharing
import SwiftUI

@MainActor
@Observable
final class CountdownModel: Identifiable {
  let id: UUID
  var secondsElapsed = 0
  var onFinish: () -> Void
  = unimplemented("CountdownModel.onFinish")
  
  @ObservationIgnored @SharedReader(.userSettings) var userSettings
  @ObservationIgnored @Dependency(\.continuousClock) var clock
  
  init() {
    @Dependency(\.uuid) var uuid
    self.id = uuid()
  }
  
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
            self.isTimerFinished
            ? { self.onFinish() }()
            : { self.secondsElapsed += 1 }()
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
      .font(.system(size: 100))
      .fontWeight(.bold)
      .foregroundColor(.white)
      .shadow(radius: 4)
      .padding(.bottom, 64)
      .task { await self.model.task() }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background { Color.black.ignoresSafeArea().opacity(0.25) }
  }
}

// MARK: - SwiftUI Previews

#Preview("Settings") {
  @Shared(.userSettings) var userSettings
  $userSettings.countdownTimer.withLock { $0 = 30 }
  
  return Color.blue.ignoresSafeArea().overlay {
    CountdownView(model: CountdownModel())
  }
}
