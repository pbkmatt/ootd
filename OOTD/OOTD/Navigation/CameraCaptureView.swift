import SwiftUI
import AVFoundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

struct CameraCaptureView: View {
    @Binding var capturedImage: UIImage?
    @StateObject private var cameraModel = CameraModel()
    @State private var isPostOOTDViewPresented: Bool = false
    
    // New state for blocking
    @State private var canPostToday: Bool = false
    
    var body: some View {
        ZStack {
            // Camera preview
            if cameraModel.previewLayer != nil {
                CameraPreview(cameraModel: cameraModel)
                    .ignoresSafeArea(edges: .all)
            } else {
                Text("Loading Camera...")
                    .foregroundColor(.white)
                    .font(.title)
                    .onAppear {
                        cameraModel.checkAuthorization()
                    }
            }
            
            VStack {
                Spacer()
                
                // Buttons
                HStack(spacing: 40) {
                    // Flip Camera
                    Button(action: {
                        cameraModel.toggleCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    
                    // Capture Photo Button (Disabled if already posted)
                    Button(action: {
                        cameraModel.takePhoto()
                    }) {
                        Circle()
                            .fill(canPostToday ? Color.white : Color.gray)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 4)
                                    .frame(width: 90, height: 90)
                            )
                    }
                    .disabled(!canPostToday)
                    
                    // Flash Toggle
                    Button(action: {
                        cameraModel.flashMode = cameraModel.flashMode == .off ? .on : .off
                    }) {
                        Image(systemName: cameraModel.flashMode == .off ? "bolt.slash" : "bolt.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onDisappear {
            if cameraModel.capturedImage == nil {
                cameraModel.stopSession()
            }
        }
        .onAppear {
            checkIfUserCanPostToday()
        }
        .onChange(of: cameraModel.capturedImage) {
            if let newImage = cameraModel.capturedImage {
                capturedImage = newImage
                isPostOOTDViewPresented = true
            }
        }
        .sheet(isPresented: $isPostOOTDViewPresented) {
            if let image = capturedImage {
                PostOOTDView(capturedImage: image)
            }
        }
    }
    
    // Check if user posted since today's 4 AM EST
    private func checkIfUserCanPostToday() {
        guard let uid = Auth.auth().currentUser?.uid else {
            canPostToday = false
            return
        }
        let db = Firestore.firestore()
        
        let today4AM = Date.today4AMInEST()
        // Query "posts" for your user where timestamp >= today4AM
        db.collection("posts")
            .whereField("uid", isEqualTo: uid)
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today4AM))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking today's post: \(error.localizedDescription)")
                    canPostToday = false
                    return
                }
                guard let docs = snapshot?.documents else {
                    canPostToday = true
                    return
                }
                // If there's at least 1 doc => user posted
                canPostToday = docs.isEmpty // no doc => can post
            }
    }
}
