import SwiftUI

struct CalculatorOverlayView: View {
    @Binding var isPresented: Bool
    @State private var display = ""

    let columns = [
        GridItem(.flexible()), GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible())
    ]

    let buttons: [CalculatorButton] = [
        .digit("7"), .digit("8"), .digit("9"), .operation("÷"),
        .digit("4"), .digit("5"), .digit("6"), .operation("×"),
        .digit("1"), .digit("2"), .digit("3"), .operation("−"),
        .digit("0"), .decimal("."), .clear("C"), .operation("+")
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding()
                }
            }

            // 显示区域
            Text(display)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)

            // 按钮网格
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(buttons, id: \.self) { button in
                    CalculatorButtonView(button: button) {
                        handleInput(button)
                    }
                }
            }

            // 单独放“=”
            Button(action: {
                handleInput(.equal("="))
            }) {
                Text("=")
                    .font(.system(size: 28, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 70)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(35)
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(30)
        .padding()
        .shadow(radius: 10)
    }

    func handleInput(_ input: CalculatorButton) {
        switch input {
        case .digit(let value), .operation(let value), .decimal(let value):
            display += value
        case .clear:
            display = ""
        case .equal:
            let expression = display
                .replacingOccurrences(of: "×", with: "*")
                .replacingOccurrences(of: "÷", with: "/")
                .replacingOccurrences(of: "−", with: "-")
            let exp = NSExpression(format: expression)
            if let result = exp.expressionValue(with: nil, context: nil) as? NSNumber {
                display = result.stringValue
            } else {
                display = "Error"
            }
        }
    }
}

// MARK: - 按钮模型

enum CalculatorButton: Hashable {
    case digit(String)
    case operation(String)
    case decimal(String)
    case clear(String)
    case equal(String)

    var label: String {
        switch self {
        case .digit(let val), .operation(let val), .decimal(let val), .clear(let val), .equal(let val):
            return val
        }
    }

    var backgroundColor: Color {
        switch self {
        case .operation, .equal:
            return .orange
        case .clear:
            return .gray
        default:
            return Color(.darkGray)
        }
    }
}

// MARK: - 按钮视图

struct CalculatorButtonView: View {
    let button: CalculatorButton
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(button.label)
                .font(.system(size: 28, weight: .semibold))
                .frame(width: 70, height: 70)
                .background(button.backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(35)
        }
    }
}
