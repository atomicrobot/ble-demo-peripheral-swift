import SwiftUI

struct ContentView: View {
    @EnvironmentObject var peripheralManager: PeripheralManager

    var body: some View {
        Text("Hello, World!")
            .padding()
            .frame(width: 300, height: 200)
            .onAppear {
                peripheralManager.start()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
