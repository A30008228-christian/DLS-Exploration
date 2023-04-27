import Foundation
import RegexBuilder

let example = """
{
"global": {
  "Dark Purple": {
    "value": "#750EFC",
    "type": "color"
  }
},
"$themes": [],
"$metadata": {
  "tokenSetOrder": [
    "global"
  ]
}
}
"""

enum TokenError: Error {
  case Placeholder
}

/*
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x30",
          "green" : "0x2D",
          "red" : "0x2B"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
*/
struct ColorAsset: Encodable {

  struct ColorInformation: Encodable {

    struct Color: Encodable {
      struct Component: Encodable {
        let alpha: String
        let blue: String
        let green: String
        let red: String
      }

      enum CodingKeys: String, CodingKey {
        case colorSpace = "color-space"
        case components
      }

      let colorSpace = "srgb"
      let components: Component

      func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(colorSpace, forKey: .colorSpace)
        try container.encode(components, forKey: .components)
      }

    }

    let color: Color
    let idiom = "universal"
  }

  struct Info: Encodable {
    let author = "xcode"
    let version = 1
  }

  var colors: [ColorInformation]
  var info = Info()

  init(value: String) throws {
    guard let match = value.firstMatch(of: regex) else {
      throw TokenError.Placeholder
    }
    let red = "0x\(match.1)"
    let green = "0x\(match.2)"
    let blue = "0x\(match.3)"

    self.colors = [
      ColorInformation(color:
          .init(components:
              .init(alpha: "1.000", blue: blue, green: green, red: red)
          )
      )
    ]
  }
}

let regex = Regex {
  "#"
  Capture {
    One(.hexDigit)
    One(.hexDigit)
  }
  Capture {
    One(.hexDigit)
    One(.hexDigit)
  }
  Capture {
    One(.hexDigit)
    One(.hexDigit)
  }
}

enum TokenType {
  case color(value: String, title: String)
}

func decodeDataIntoTokens(data: Data) throws -> [TokenType] {
  // make sure this JSON is in the format we expect
  if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
      // try to read out a string array
    if let colorNames = json["global"] as? [String: [String: String]] {
      let converted = colorNames.compactMap { colorName -> TokenType? in
        guard let colorValue = colorName.value["value"] else {
          return nil
        }
        return TokenType.color(value: colorValue, title: colorName.key)
      }
      return converted
    }
  }
  return []
}

func tokenToAsset(token: TokenType) -> ColorAsset {
  switch token {
  case .color(value: let value, title: _):
    return try! ColorAsset(value: value)
  }
}

let filePath = "tokens.json"
let fileManager = FileManager.default

guard let data = fileManager.contents(atPath: "\(fileManager.currentDirectoryPath)/../tokens.json") else {
  throw TokenError.Placeholder
}
do {
  // Extract from file
  // Decode
  let tokens = try decodeDataIntoTokens(data: data)

  // Encode to single page

  print(tokens)

  let data = try JSONEncoder().encode(tokens.map { tokenToAsset(token: $0) })



  let encoder = JSONEncoder()
  encoder.outputFormatting = .prettyPrinted

  let path = "\(fileManager.currentDirectoryPath)/../iOSDLS/Sources/Resources/Colors.xcassets"
  tokens.forEach {
    switch $0 {
    case .color(value: _, title: let title):
      let asset = tokenToAsset(token: $0)
      let result = try! encoder.encode(asset)
      try! fileManager.createDirectory(atPath: "\(path)/\(title).colorset", withIntermediateDirectories: true)
      print(fileManager.createFile(atPath: "\(path)/\(title).colorset/Contents.json", contents: result))

      print(fileManager.createFile(atPath: "\(path)/Contents.json", contents: try! encoder.encode(EmptyInfo())))
    }
  }

}

struct EmptyInfo: Encodable {
  let info = ColorAsset.Info()
}


