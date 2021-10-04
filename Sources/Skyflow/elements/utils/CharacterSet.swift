import Foundation

extension CharacterSet {
      /// Ascii decimal digits set.
    public static var SkyflowAsciiDecimalDigits: CharacterSet {
        return self.init(charactersIn: "0123456789")
    }
}
