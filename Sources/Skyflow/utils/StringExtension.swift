//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 25/12/21.
//

import Foundation

extension String {

    func replacingFirstOccurrence(of target: String, with replacement: String) -> String {
        guard let range = self.range(of: target) else { return self }
        return self.replacingCharacters(in: range, with: replacement)
    }
}
