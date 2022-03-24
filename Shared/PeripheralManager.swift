import Combine
import CoreBluetooth
import Foundation

class PeripheralManager: NSObject, ObservableObject {
    var manager: CBPeripheralManager!
    static let serviceUUID1 = CBUUID(string: "7673a7b0-4595-488b-a376-b95c7278781c")
    static let serviceUUID2 = CBUUID(string: "7673a7b1-4595-488b-a376-b95c7278781c")
    static let serviceUUID3 = CBUUID(string: "7673a7b2-4595-488b-a376-b95c7278781c")
    static let serviceUUID4 = CBUUID(string: "7673a7b3-4595-488b-a376-b95c7278781c")
    static let service1 = CBMutableService(type: serviceUUID1, primary: true)
    static let service2 = CBMutableService(type: serviceUUID2, primary: true)
    static let service3 = CBMutableService(type: serviceUUID3, primary: true)
    static let service4 = CBMutableService(type: serviceUUID4, primary: true)

    static let echoCharacteristicUUID = CBUUID(string: "a575bce0-a1a1-4040-8d3f-11cbd07df6cf")
    static let timerCharacteristicUUID = CBUUID(string: "a575bce1-a1a1-4040-8d3f-11cbd07df6cf")
    static let characteristicUUID3 = CBUUID(string: "a575bce2-a1a1-4040-8d3f-11cbd07df6cf")
    static let characteristicUUID4 = CBUUID(string: "a575bce3-a1a1-4040-8d3f-11cbd07df6cf")
    static let echoCharacteristic = CBMutableCharacteristic(type: echoCharacteristicUUID,
                                                            properties: [.write, .read],
                                                            value: nil,
                                                            permissions: [.writeable, .readable])
    static let timerCharacteristic = CBMutableCharacteristic(type: timerCharacteristicUUID,
                                                             properties: [.read, .notify],
                                                             value: nil,
                                                             permissions: [.writeable, .readable])
    static let characteristic3 = CBMutableCharacteristic(type: characteristicUUID3,
                                                         properties: [.write, .read, .notify],
                                                         value: nil,
                                                         permissions: [.writeable, .readable])
    static let characteristic4 = CBMutableCharacteristic(type: characteristicUUID4,
                                                         properties: [.write, .read, .notify],
                                                         value: nil,
                                                         permissions: [.writeable, .readable])
    static let characteristics = [
        echoCharacteristic,
        timerCharacteristic//,
        //        characteristic3,
        //        characteristic4
    ]
    let advertisementDataLocalNameKey = "HelloWorld"
    let formatter: ISO8601DateFormatter
    var echoValue = Data()
    var cancellables = Set<AnyCancellable>()

    override init() {
        formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        super.init()
    }

    func start() {
        manager = CBPeripheralManager(delegate: self, queue: nil)

        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .scan(0) { counter, _ in
                counter + 1
            }
            .sink { [weak self] value in
                guard let data = String(value).data(using: .utf8) else { return }
                self?.manager.updateValue(data, for: PeripheralManager.timerCharacteristic, onSubscribedCentrals: nil)
            }
            .store(in: &cancellables)
    }
}

extension PeripheralManager: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard manager.state == .poweredOn else { return }

        PeripheralManager.service1.characteristics = PeripheralManager.characteristics

        manager.add(PeripheralManager.service1)
        manager.add(PeripheralManager.service2)
        manager.add(PeripheralManager.service3)
        manager.add(PeripheralManager.service4)

        print("\(formatter.string(from: Date())) Starting advertisement")
        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [PeripheralManager.serviceUUID1,
                                                                       PeripheralManager.serviceUUID2,
                                                                       PeripheralManager.serviceUUID3,
                                                                       PeripheralManager.serviceUUID4],
                                     CBAdvertisementDataLocalNameKey: advertisementDataLocalNameKey])
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("\(formatter.string(from: Date())) didReceiveRead")
        if request.characteristic == PeripheralManager.echoCharacteristic {
            request.value = echoValue
        } else if request.characteristic == PeripheralManager.timerCharacteristic {

        }
        else {
            let data: Data = Data([0, 0, 0, 0, 0])
            request.value = data
        }

        manager.respond(to: request,
                        withResult: .success)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if let request = requests.first,
           let data = request.value {
            print("\(formatter.string(from: Date())) Received data: \(String(decoding: data, as: UTF8.self))")
            if request.characteristic == PeripheralManager.echoCharacteristic {
                echoValue = data
                manager.updateValue(data, for: PeripheralManager.echoCharacteristic, onSubscribedCentrals: nil)
            }
        }
    }
}
