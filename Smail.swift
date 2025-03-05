import SwiftUI
import Network
import CoreLocation
import UserNotifications
import MobileCoreServices
import AVKit

class EmailManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var messages: [Message] = []
    @Published var availableUsers: [(id: String, location: CLLocation)] = []
    @Published var selectedUsers: Set<String> = []
    @Published var userLocation: CLLocation?
    @Published var isUploadingFile = false
    @Published var fileURL: URL?
    @Published var isSendingMessage = false
    @Published var isShowingMessageSheet = false
    @Published var isShowingUserList = false
    @Published var isShowingControls = false
    @Published var isFileUploaded = false
    @Published var searchQuery = ""

    var connection: NWConnection?
    var listener: NWListener?
    var listenerPort: UInt16 = 12345
    var locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        requestNotificationPermission()
        setupListener()
    }

    func setupListener() {
        do {
            let parameters = NWParameters(tls: nil)
            parameters.requiredInterfaceType = .wifi
            listener = try NWListener(using: parameters, on: listenerPort)
            listener?.newConnectionHandler = { newConnection in
                self.handleIncomingConnection(newConnection)
            }
            listener?.start(queue: .main)
        } catch {
            print("Error setting up listener: \(error)")
        }
    }

    func handleIncomingConnection(_ connection: NWConnection) {
        self.connection = connection
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.receiveMessage(from: connection)
            default:
                break
            }
        }
        connection.start(queue: .main)
    }

    func receiveMessage(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1000) { data, _, isComplete, _ in
            if let data = data, isComplete {
                if let message = try? JSONDecoder().decode(Message.self, from: data) {
                    DispatchQueue.main.async {
                        self.messages.append(message)
                    }
                }
                self.receiveMessage(from: connection)
            }
        }
    }

    func sendMessage(_ content: String) {
        isSendingMessage = true
        let message = Message(sender: "Device", content: content, timestamp: Date())
        if let data = try? JSONEncoder().encode(message), let connection = connection {
            connection.send(content: data, completion: .contentProcessed({ error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.messages.append(message)
                        self.isSendingMessage = false
                    }
                }
            }))
        }
    }

    func uploadFile() {
        guard let fileURL = fileURL else { return }
        let fileData = try? Data(contentsOf: fileURL)
        if let data = fileData, let connection = connection {
            isUploadingFile = true
            connection.send(content: data, completion: .contentProcessed({ error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.isUploadingFile = false
                    }
                }
            }))
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func sendNotification(for message: Message) {
        let content = UNMutableNotificationContent()
        content.title = "Nova Mensagem de \(message.sender)"
        content.body = message.content
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func updateFileURL(url: URL) {
        self.fileURL = url
    }

    func sendToMultipleUsers(content: String) {
        let message = Message(sender: "Device", content: content, timestamp: Date())
        if let data = try? JSONEncoder().encode(message), let connection = connection {
            connection.send(content: data, completion: .contentProcessed({ error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.messages.append(message)
                    }
                }
            }))
        }
    }
}

struct Message: Identifiable, Codable {
    var id = UUID()
    var sender: String
    var content: String
    var timestamp: Date
    var fileURL: URL?
}

struct EmailAppView: View {
    @StateObject var emailManager = EmailManager()
    @State private var messageText = ""

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Filtrar e-mails", text: $emailManager.searchQuery)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .font(.custom("NoteWorthy", size: 18))
                    
                    Button(action: {
                        emailManager.searchQuery = ""
                    }) {
                        Image(systemName: "x.circle.fill")
                            .font(.title)
                            .foregroundColor(.pink)
                    }
                }
                .padding()

                ScrollView {
                    ForEach(emailManager.messages.filter {
                        emailManager.searchQuery.isEmpty || $0.content.localizedCaseInsensitiveContains(emailManager.searchQuery)
                    }.reversed()) { message in
                        NavigationLink(destination: EmailDetailView(message: message)) {
                            EmailCardView(message: message)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .sheet(isPresented: $emailManager.isShowingMessageSheet) {
                NewMessageSheet(emailManager: emailManager)
            }
            .sheet(isPresented: $emailManager.isShowingUserList) {
                UserListSheet(emailManager: emailManager)
            }
            .sheet(isPresented: $emailManager.isShowingControls) {
                ControlsSheet(emailManager: emailManager)
            }
        }
    }
}

struct EmailCardView: View {
    var message: Message

    var body: some View {
        VStack {
            HStack {
                Text(message.sender)
                    .font(.custom("NoteWorthy", size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text(message.timestamp, style: .time)
                    .font(.custom("NoteWorthy", size: 12))
                    .foregroundColor(.gray)
            }
            Text(message.content)
                .padding()
                .background(Color.pink.opacity(0.2))
                .cornerRadius(10)
                .font(.custom("NoteWorthy", size: 16))
        }
        .padding()
        .background(Color.pink.opacity(0.1))
        .cornerRadius(10)
    }
}

struct EmailDetailView: View {
    var message: Message
    
    var body: some View {
        VStack {
            Text(message.sender)
                .font(.custom("NoteWorthy", size: 22))
                .foregroundColor(.pink)
                .bold()
            
            Text(message.content)
                .font(.custom("NoteWorthy", size: 18))
                .foregroundColor(.black)
                .padding()
            
            if let fileURL = message.fileURL {
                if fileURL.pathExtension == "jpg" || fileURL.pathExtension == "png" {
                    Image(uiImage: UIImage(contentsOfFile: fileURL.path) ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300)
                } else if fileURL.pathExtension == "mp4" {
                    VideoPlayer(player: AVPlayer(url: fileURL))
                        .frame(height: 300)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct NewMessageSheet: View {
    @ObservedObject var emailManager: EmailManager
    @State private var messageText = ""

    var body: some View {
        VStack {
            Text("Nova Mensagem")
                .font(.custom("NoteWorthy", size: 22))
                .foregroundColor(.pink)
                .bold()
            
            TextField("Digite sua mensagem", text: $messageText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .font(.custom("NoteWorthy", size: 18))
            
            HStack {
                Button(action: { emailManager.isShowingUserList.toggle() }) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {
                    emailManager.sendMessage(messageText)
                    emailManager.isShowingMessageSheet = false
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(10)
                }
                .padding()
            }
            Spacer()
        }
        .padding()
    }
}

struct UserListSheet: View {
    @ObservedObject var emailManager: EmailManager

    var body: some View {
        NavigationStack {
            VStack {
                Text("Usuários Disponíveis")
                    .font(.custom("NoteWorthy", size: 22))
                    .foregroundColor(.pink)
                    .bold()
                
                List(emailManager.availableUsers, id: \.id) { user in
                    Button(action: {
                        emailManager.selectedUsers.insert(user.id)
                    }) {
                        Text(user.id)
                            .font(.custom("NoteWorthy", size: 18))
                            .foregroundColor(.black)
                    }
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        emailManager.isShowingUserList = false
                    }) {
                        Text("Fechar")
                            .font(.custom("NoteWorthy", size: 18))
                            .foregroundColor(.pink)
                    }
                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct ControlsSheet: View {
    @ObservedObject var emailManager: EmailManager

    var body: some View {
        VStack {
            Button(action: {
                emailManager.isShowingControls = false
            }) {
                Text("Fechar Controles")
                    .font(.custom("NoteWorthy", size: 18))
                    .foregroundColor(.pink)
            }
            Spacer()
        }
        .padding()
    }
}
