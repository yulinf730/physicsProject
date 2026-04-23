//
//  CalculatorOverlayView.swift
//  physicsProject
//
//  Created by Yulin Feng on 2025/10/21.
//


import SwiftUI
import Foundation

struct CalculatorOverlayView: View {
    @Binding var isPresented: Bool
    @State private var display = ""

    let columns = [
        GridItem(.flexible()), GridItem(.flexible()),
        GridItem(.flexible()), GridItem(.flexible())
    ]

    let buttons: [CalculatorButton] = [
        .leftParenthesis("("), .rightParenthesis(")"), .squareRoot("√"), .square("x²"),
        .digit("7"), .digit("8"), .digit("9"), .operation("×"),
        .digit("4"), .digit("5"), .digit("6"), .operation("−"),
        .digit("1"), .digit("2"), .digit("3"), .operation("+"),
        .clear("C"), .digit("0"), .decimal("."), .operation("÷")
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
            Text(displayText)
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

    private var displayText: String {
        display.isEmpty ? "0" : display
    }

    private let calculatorFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 12
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    func handleInput(_ input: CalculatorButton) {
        switch input {
        case .digit(let value):
            handleDigit(value)
        case .operation(let value):
            handleOperation(value)
        case .decimal(let value):
            handleDecimal(value)
        case .leftParenthesis:
            handleLeftParenthesis()
        case .rightParenthesis:
            handleRightParenthesis()
        case .square:
            handleSquare()
        case .squareRoot:
            handleSquareRoot()
        case .clear:
            display = ""
        case .equal:
            guard let result = evaluateDisplay() else {
                display = "Error"
                return
            }
            display = format(result)
        }
    }

    private func handleDigit(_ value: String) {
        if display == "Error" {
            display = value
            return
        }

        if let last = display.last, needsImplicitMultiplication(after: last) {
            display += "×"
        }

        display += value
    }

    private func handleOperation(_ value: String) {
        if display == "Error" {
            display = ""
        }

        if display.isEmpty {
            if value == "−" {
                display = value
            }
            return
        }

        if let last = display.last, last == "(" || last == "√" {
            if value == "−" {
                display += value
            }
            return
        }

        if let last = display.last, isOperator(last) {
            if value == "−" && last != "−" {
                display += value
                return
            }

            display.removeLast()

            if let newLast = display.last, isOperator(newLast) {
                display.removeLast()
            }

            guard display.isEmpty == false else {
                if value == "−" {
                    display = value
                }
                return
            }
        }

        display += value
    }

    private func handleDecimal(_ value: String) {
        if display == "Error" {
            display = "0\(value)"
            return
        }

        if let last = display.last, needsImplicitMultiplication(after: last) {
            display += "×0\(value)"
            return
        }

        if display.isEmpty || (display.last.map(isOperator) ?? false) || display.last == "(" {
            display += "0\(value)"
            return
        }

        let currentSegment = currentNumberSegment(in: display)
        guard currentSegment.contains(value) == false else { return }
        display += value
    }

    private func handleLeftParenthesis() {
        if display == "Error" {
            display = "("
            return
        }

        if let last = display.last, needsImplicitMultiplication(after: last) {
            display += "×("
            return
        }

        display += "("
    }

    private func handleRightParenthesis() {
        guard display != "Error" else { return }
        guard unmatchedLeftParentheses > 0 else { return }
        guard let last = display.last, canEndExpression(with: last) else { return }
        display += ")"
    }

    private func handleSquare() {
        guard display != "Error" else { return }
        guard let last = display.last, canEndExpression(with: last) else { return }
        display += "²"
    }

    private func handleSquareRoot() {
        if display == "Error" {
            display = "√("
            return
        }

        if let last = display.last, needsImplicitMultiplication(after: last) {
            display += "×√("
            return
        }

        display += "√("
    }

    private func evaluateDisplay() -> Double? {
        var parser = CalculatorExpressionParser(expression: display)
        guard let result = parser.parse(),
              result.isFinite else {
            return nil
        }

        return result
    }

    private func needsImplicitMultiplication(after character: Character) -> Bool {
        isCalculatorDigit(character) || character == ")" || character == "²"
    }

    private func currentNumberSegment(in text: String) -> Substring {
        var index = text.endIndex

        while index > text.startIndex {
            let previousIndex = text.index(before: index)
            let character = text[previousIndex]

            if isOperator(character) || character == "(" || character == ")" || character == "√" || character == "²" {
                return text[index...]
            }

            index = previousIndex
        }

        return text[...]
    }

    private func isOperator(_ character: Character) -> Bool {
        ["+", "−", "×", "÷"].contains(character)
    }

    private func canEndExpression(with character: Character) -> Bool {
        isCalculatorDigit(character) || character == ")" || character == "²"
    }

    private var unmatchedLeftParentheses: Int {
        var count = 0

        for character in display {
            if character == "(" {
                count += 1
            } else if character == ")" {
                count = max(0, count - 1)
            }
        }

        return count
    }

    private func format(_ value: Double) -> String {
        let normalizedValue = abs(value) < 1e-12 ? 0 : value
        return calculatorFormatter.string(from: NSNumber(value: normalizedValue))
            ?? NSNumber(value: normalizedValue).stringValue
    }

    private func isCalculatorDigit(_ character: Character) -> Bool {
        "0123456789".contains(character)
    }
}

private struct CalculatorExpressionParser {
    private let characters: [Character]
    private var index = 0

    init(expression: String) {
        self.characters = Array(expression)
    }

    mutating func parse() -> Double? {
        guard characters.isEmpty == false,
              let value = parseExpression(),
              index == characters.count else {
            return nil
        }

        return value
    }

    private mutating func parseExpression() -> Double? {
        guard var value = parseTerm() else { return nil }

        while let next = peek(), next == "+" || next == "−" {
            advance()
            guard let rhs = parseTerm() else { return nil }
            value = next == "+" ? value + rhs : value - rhs
        }

        return value
    }

    private mutating func parseTerm() -> Double? {
        guard var value = parseFactor() else { return nil }

        while let next = peek(), next == "×" || next == "÷" {
            advance()
            guard let rhs = parseFactor() else { return nil }

            if next == "×" {
                value *= rhs
            } else {
                guard rhs != 0 else { return nil }
                value /= rhs
            }
        }

        return value
    }

    private mutating func parseFactor() -> Double? {
        guard var value = parseUnary() else { return nil }

        while match("²") {
            value *= value
        }

        return value
    }

    private mutating func parseUnary() -> Double? {
        if match("−") {
            guard let value = parseUnary() else { return nil }
            return -value
        }

        if match("√") {
            guard let value = parseUnary(),
                  value >= 0 else { return nil }
            return value.squareRoot()
        }

        return parsePrimary()
    }

    private mutating func parsePrimary() -> Double? {
        if match("(") {
            guard let value = parseExpression(),
                  match(")") else {
                return nil
            }

            return value
        }

        return parseNumber()
    }

    private mutating func parseNumber() -> Double? {
        let startIndex = index
        var hasDecimalPoint = false

        while let next = peek() {
            if isCalculatorDigit(next) {
                advance()
            } else if next == "." && hasDecimalPoint == false {
                hasDecimalPoint = true
                advance()
            } else {
                break
            }
        }

        guard startIndex != index else { return nil }

        let numberString = String(characters[startIndex..<index])
        guard numberString != "." else { return nil }
        return Double(numberString)
    }

    private func peek() -> Character? {
        guard index < characters.count else { return nil }
        return characters[index]
    }

    @discardableResult
    private mutating func match(_ expected: Character) -> Bool {
        guard peek() == expected else { return false }
        advance()
        return true
    }

    private mutating func advance() {
        index += 1
    }

    private func isCalculatorDigit(_ character: Character) -> Bool {
        "0123456789".contains(character)
    }
}

// MARK: - 按钮模型

enum CalculatorButton: Hashable {
    case digit(String)
    case operation(String)
    case decimal(String)
    case clear(String)
    case equal(String)
    case square(String)
    case squareRoot(String)
    case leftParenthesis(String)
    case rightParenthesis(String)

    var label: String {
        switch self {
        case .digit(let val),
             .operation(let val),
             .decimal(let val),
             .clear(let val),
             .equal(let val),
             .square(let val),
             .squareRoot(let val),
             .leftParenthesis(let val),
             .rightParenthesis(let val):
            return val
        }
    }

    var backgroundColor: Color {
        switch self {
        case .operation, .equal, .square, .squareRoot, .leftParenthesis, .rightParenthesis:
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
