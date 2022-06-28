/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

extension CharacterSet {
      /// Ascii decimal digits set.
    public static var SkyflowAsciiDecimalDigits: CharacterSet {
        return self.init(charactersIn: "0123456789")
    }
    
    public static var CardHolderCharacters: CharacterSet {
        let specials = self.init(charactersIn: ".' ")
        return CharacterSet.letters.union(specials)
    }
    
}
