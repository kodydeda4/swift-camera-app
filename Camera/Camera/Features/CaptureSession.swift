import AsyncAlgorithms
import AVFoundation
import ComposableArchitecture
import PhotosUI
import SwiftUI

@Reducer
public struct CaptureSession {
  
  @ObservableState
  public struct State: Equatable {
    internal var isRecording = false
    internal var recordingDurationSeconds = 0
    internal let avCaptureSession = AVCaptureSession()
    internal var avCaptureDevice: AVCaptureDevice?
    internal var avCaptureDeviceInput: AVCaptureDeviceInput?
    internal var avCaptureMovieFileOutput = AVCaptureMovieFileOutput()
    internal let avVideoAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    internal let avVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    internal var recordingDelegate = MovieCaptureDelegate()
    internal var isVideoPermissionGranted: Bool { avVideoAuthorizationStatus == .authorized }
  }
  
  public enum Action: ViewAction {
    case view(View)
    case requestDefaultAVCaptureDeviceResponse(AVCaptureDevice?)
    case recievedRecordingDelegateEvent(MovieCaptureDelegate.Event)
    
    public enum View: BindableAction {
      case task
      case recordingButtonTapped
      case endSessionButtonTapped
      case binding(BindingAction<State>)
    }
  }
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    BindingReducer(action: \.view)
    Reduce { state, action in
      switch action {
        
      case let .requestDefaultAVCaptureDeviceResponse(value):
        return self.startCaptureSession(&state, value)
        
      case let .recievedRecordingDelegateEvent(event):
        return self.handleRecordingDelegateEvent(&state, event)
        
      case let .view(action):
        switch action {
          
        case .task:
          return task(state)
          
        case .binding:
          return .none
          
        case .recordingButtonTapped:
//          return !state.isRecording ? startRecording(&state) : stopRecording(&state)
          return .none
          
        case .endSessionButtonTapped:
//          return endSession(state)
          return .none
        }
      }
    }
  }
}

extension CaptureSession {
  internal func startCaptureSession(
    _ state: inout State,
    _ value: AVCaptureDevice?
  ) -> EffectOf<Self> {
    state.avCaptureDevice = value
    
    guard let value else {
      print("❌ requestDefaultAVCaptureDeviceResponse is false")
      return .none
    }
    
    state.avCaptureDeviceInput = try? AVCaptureDeviceInput(device: value)
    
    guard let input = state.avCaptureDeviceInput else {
      print("❌ avCaptureDeviceInput is nil")
      return .none
    }
    
    let output = state.avCaptureMovieFileOutput
    
    print("✅ input and output are non-nil")
    
    if state.avCaptureSession.canAddInput(input) {
      state.avCaptureSession.addInput(input)
      print("✅ added input")
    }
    if state.avCaptureSession.canAddOutput(output) {
      state.avCaptureSession.addOutput(output)
      print("✅ added output")
    }
    state.avVideoPreviewLayer.session = state.avCaptureSession
    return .run { [avCaptureSession = state.avCaptureSession] _ in
      avCaptureSession.startRunning()
      print("✅ captureSession.startRunning()")
    }
  }
}

// MARK: - SwiftUI

@ViewAction(for: CaptureSession.self)
public struct CaptureSessionView: View {
  @Bindable public var store: StoreOf<CaptureSession>
  
  public init(store: StoreOf<CaptureSession>) {
    self.store = store
  }
  
  public var body: some View {
    NavigationStack {
      AVCaptureVideoPreviewLayerView(avVideoPreviewLayer: store.avVideoPreviewLayer)
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .overlay(content: self.overlay)
    .task { await send(.task).finish() }
  }
}

extension CaptureSessionView {
  @MainActor internal func overlay() -> some View {
    VStack {
      Spacer()
      self.debugView
      self.footer
    }
  }

  @MainActor private var footer: some View {
    HStack {
      Button(store.isRecording ? "Start Recording" : "Stop Recording") {
        send(.recordingButtonTapped)
      }
      Button("End Session") {
        send(.endSessionButtonTapped)
      }
    }
    .buttonStyle(.borderedProminent)
  }

  @MainActor private var debugView: some View {
    GroupBox {
      VStack(alignment: .leading) {
        debugLine("isPermissionGranted", store.isVideoPermissionGranted.description)
        debugLine("isCaptureSessionRunning", store.avCaptureSession.isRunning.description)
        debugLine("isRecording", store.isRecording.description)
      }
    }
    .padding()
  }

  @MainActor private func debugLine(_ title: String, _ description: String) -> some View {
    HStack {
      Text("\(title):")
        .bold()
      Text(description)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

extension CaptureSession {
  internal func handleRecordingDelegateEvent(
    _ state: inout State,
    _ event: MovieCaptureDelegate.Event
  ) -> EffectOf<Self> {
    switch event {
      
    case let .fileOutput(
      output,
      didFinishRecordingTo: outputFileURL,
      from: connections,
      error: error
    ):
      print(output, outputFileURL, connections, error as Any)
      
      return .run { _ in
        let isPhotoLibraryReadWriteAccessGranted: Bool = await {
          let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
          var isAuthorized = status == .authorized
          
          if status == .notDetermined {
            isAuthorized = await PHPhotoLibrary
              .requestAuthorization(for: .readWrite) == .authorized
          }
          return isAuthorized
        }()
        
        guard isPhotoLibraryReadWriteAccessGranted else {
          print("photo library read write access not granted.")
          return
        }
        
        try await PHPhotoLibrary.shared().performChanges {
          let creationRequest = PHAssetCreationRequest.forAsset()
          creationRequest.addResource(with: .video, fileURL: outputFileURL, options: nil)
        }
      }
    }
  }
}

extension CaptureSession {
  internal func task(_ state: State) -> EffectOf<Self> {
    return .run { [recordingDelegate = state.recordingDelegate] send in
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask {
          await send(.requestDefaultAVCaptureDeviceResponse(
            AVCaptureDevice.default(for: .video)
          ))
        }
        // recording-delegate
        taskGroup.addTask {
          for await event in recordingDelegate.events {
            await send(.recievedRecordingDelegateEvent(event))
          }
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview {
  CaptureSessionView(store: Store(initialState: CaptureSession.State()) {
    CaptureSession()
  })
}
