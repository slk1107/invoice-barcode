//
//  Code128Renderer.swift
//  InvoiceBarcode
//
//  Created by Kris Lin on 2025/9/14.
//

import UIKit
import CoreGraphics

// MARK: - Code 128 Direct Renderer
class Code128Renderer {
    
    // Code 128B character set and patterns
    private static let code128B: [String: (value: Int, pattern: String)] = [
        " ": (0, "11011001100"),
        "!": (1, "11001101100"),
        "\"": (2, "11001100110"),
        "#": (3, "10010011000"),
        "$": (4, "10010001100"),
        "%": (5, "10001001100"),
        "&": (6, "10011001000"),
        "'": (7, "10011000100"),
        "(": (8, "10001100100"),
        ")": (9, "11001001000"),
        "*": (10, "11001000100"),
        "+": (11, "11000100100"),
        ",": (12, "10110011100"),
        "-": (13, "10011011100"),
        ".": (14, "10011001110"),
        "/": (15, "10111001100"),
        "0": (16, "10011101100"),
        "1": (17, "10011100110"),
        "2": (18, "11001110010"),
        "3": (19, "11001011100"),
        "4": (20, "11001001110"),
        "5": (21, "11011100100"),
        "6": (22, "11001110100"),
        "7": (23, "11101101110"),
        "8": (24, "11101001100"),
        "9": (25, "11100101100"),
        ":": (26, "11100100110"),
        ";": (27, "11101100100"),
        "<": (28, "11100110100"),
        "=": (29, "11100110010"),
        ">": (30, "11011011000"),
        "?": (31, "11011000110"),
        "@": (32, "11000110110"),
        "A": (33, "10100011000"),
        "B": (34, "10001011000"),
        "C": (35, "10001000110"),
        "D": (36, "10110001000"),
        "E": (37, "10001101000"),
        "F": (38, "10001100010"),
        "G": (39, "11010001000"),
        "H": (40, "11000101000"),
        "I": (41, "11000100010"),
        "J": (42, "10110111000"),
        "K": (43, "10110001110"),
        "L": (44, "10001101110"),
        "M": (45, "10111011000"),
        "N": (46, "10111000110"),
        "O": (47, "10001110110"),
        "P": (48, "11101110110"),
        "Q": (49, "11010001110"),
        "R": (50, "11000101110"),
        "S": (51, "11011101000"),
        "T": (52, "11011100010"),
        "U": (53, "11011101110"),
        "V": (54, "11101011000"),
        "W": (55, "11101000110"),
        "X": (56, "11100010110"),
        "Y": (57, "11101101000"),
        "Z": (58, "11101100010"),
        "[": (59, "11100011010"),
        "\\": (60, "11101111010"),
        "]": (61, "11001000010"),
        "^": (62, "11110001010"),
        "_": (63, "10100110000"),
        "`": (64, "10100001100"),
        "a": (65, "10010110000"),
        "b": (66, "10010000110"),
        "c": (67, "10000101100"),
        "d": (68, "10000100110"),
        "e": (69, "10110010000"),
        "f": (70, "10110000100"),
        "g": (71, "10011010000"),
        "h": (72, "10011000010"),
        "i": (73, "10000110100"),
        "j": (74, "10000110010"),
        "k": (75, "11000010010"),
        "l": (76, "11001010000"),
        "m": (77, "11110111010"),
        "n": (78, "11000010100"),
        "o": (79, "10001111010"),
        "p": (80, "10100111100"),
        "q": (81, "10010111100"),
        "r": (82, "10010011110"),
        "s": (83, "10111100100"),
        "t": (84, "10011110100"),
        "u": (85, "10011110010"),
        "v": (86, "11110100100"),
        "w": (87, "11110010100"),
        "x": (88, "11110010010"),
        "y": (89, "11011011110"),
        "z": (90, "11011110110"),
        "{": (91, "11110110110"),
        "|": (92, "10101111000"),
        "}": (93, "10100011110"),
        "~": (94, "10001011110")
    ]
    
    private static let startCodeB = "11010010000"
    private static let stopCode = "1100011101011"
    
    // MARK: - Generate colored barcode
    static func generateColoredBarcode(
        text: String,
        barColor: UIColor,
        backgroundColor: UIColor,
        size: CGSize
    ) -> UIImage? {
        
        // Generate the barcode pattern
        guard let pattern = generateCode128Pattern(text: text) else {
            print("Failed to generate Code 128 pattern")
            return nil
        }
        
        // Calculate module width (width of narrowest bar)
        let moduleWidth = size.width / CGFloat(pattern.count)
        
        // Create image context
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Fill background
            backgroundColor.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw bars
            barColor.setFill()
            var xPosition: CGFloat = 0
            
            for char in pattern {
                if char == "1" {
                    // Draw black bar
                    let barRect = CGRect(
                        x: xPosition,
                        y: 0,
                        width: moduleWidth,
                        height: size.height
                    )
                    cgContext.fill(barRect)
                }
                xPosition += moduleWidth
            }
        }
    }
    
    // MARK: - Generate Code 128B pattern
    private static func generateCode128Pattern(text: String) -> String? {
        var pattern = ""
        var checksum = 104 // Start Code B value
        
        // Add start code
        pattern += startCodeB
        
        // Add each character pattern and calculate checksum
        for (index, char) in text.enumerated() {
            guard let charData = code128B[String(char)] else {
                print("Unsupported character: \(char)")
                return nil
            }
            pattern += charData.pattern
            checksum += charData.value * (index + 1)
        }
        
        // Add checksum character
        let checksumValue = checksum % 103
        guard let checksumPattern = getPatternByValue(checksumValue) else {
            print("Failed to get checksum pattern")
            return nil
        }
        pattern += checksumPattern
        
        // Add stop code
        pattern += stopCode
        
        return pattern
    }
    
    // MARK: - Helper to get pattern by value
    private static func getPatternByValue(_ value: Int) -> String? {
        // Find the pattern that matches the checksum value
        for (_, data) in code128B {
            if data.value == value {
                return data.pattern
            }
        }
        
        // Handle special cases for checksum values
        // These are Code 128 control characters not in the normal character set
        let checksumPatterns: [Int: String] = [
            95: "10100001110",
            96: "10100011110",
            97: "10001110010",
            98: "11010111000",
            99: "11010110000",
            100: "11000111010",
            101: "10111101110",
            102: "10111100010",
            103: "11110101110",
            104: "11110100010", // START B
            105: "11010011100", // START C
            106: "11010010000"  // START A
        ]
        
        return checksumPatterns[value]
    }
}
