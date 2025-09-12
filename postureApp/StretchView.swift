import SwiftUI

struct Stretch: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
}

struct StretchView: View {
    @State private var seated: [Stretch] = []
    @State private var standing: [Stretch] = []

    var body: some View {
        VStack {
            List {
                Section(header: Text("💺 座ってできるストレッチ")) {
                    ForEach(seated) { stretch in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(stretch.title)
                                .font(.headline)
                            Text(stretch.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("🧍‍♂️ 立ってできるストレッチ")) {
                    ForEach(standing) { stretch in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(stretch.title)
                                .font(.headline)
                            Text(stretch.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.inset)

            Button("🔄 更新") {
                refreshStretches()
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 500) // Mac用に適度なサイズを確保
        .onAppear(perform: refreshStretches)
    }

    private func refreshStretches() {
        seated = Array(seatedStretches.shuffled().prefix(5))
        standing = Array(standingStretches.shuffled().prefix(5))
    }
}

// MARK: - サンプルデータ
fileprivate let seatedStretches: [Stretch] = [
    Stretch(title: "首回し", description: "ゆっくりと首を回して筋肉をほぐしましょう。"),
    Stretch(title: "肩すくめ", description: "肩を大きくすくめて5秒キープし、力を抜きましょう。"),
    Stretch(title: "背伸び", description: "両腕を上に伸ばし、大きく背伸びをします。"),
    Stretch(title: "足首回し", description: "片足ずつ足首をゆっくり回します。"),
    Stretch(title: "前屈みストレッチ", description: "腰から前に倒れて背中を伸ばします。"),
    Stretch(title: "腰ひねり", description: "椅子に座ったまま上半身を左右にひねります。"),
    Stretch(title: "手首ストレッチ", description: "手首を反らして指先を伸ばします。")
]

fileprivate let standingStretches: [Stretch] = [
    Stretch(title: "アキレス腱伸ばし", description: "片足を前に出し、後ろ足のアキレス腱を伸ばします。"),
    Stretch(title: "太もも前伸ばし", description: "足の甲を手で持ち、太ももの前側を伸ばします。"),
    Stretch(title: "体側伸ばし", description: "片手を頭上に伸ばし、体を横に倒します。"),
    Stretch(title: "肩回し", description: "肩を前後に大きく回します。"),
    Stretch(title: "ふくらはぎ伸ばし", description: "壁に手をついてふくらはぎを伸ばします。"),
    Stretch(title: "前屈ストレッチ", description: "腰から上体を前に倒し、背中と脚裏を伸ばします。"),
    Stretch(title: "腕クロスストレッチ", description: "片腕を胸の前で抱え込み、肩を伸ばします。")
]

// MARK: - プレビュー
struct StretchView_Previews: PreviewProvider {
    static var previews: some View {
        StretchView()
    }
}
