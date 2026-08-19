/*
 * Copyright (c) 2022 Skyflow
*/

// Composable container marker type, element creation, event wiring, and layout.
// The contract-specific collect() operation is defined per SDK target.

import Foundation
import UIKit

public class ComposableContainer: ContainerProtocol {}

public extension Container {
    package func makeComposableElement(input: BaseCollectElementInput, options: BaseCollectElementOptions? = BaseCollectElementOptions()) -> TextField where T: ComposableContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .COMPOSABLE_CONTAINER

        let skyflowElement = TextField(input: input, options: options ?? BaseCollectElementOptions(), contextOptions: tempContextOptions, elements: elements)
        elements.append(skyflowElement)
        let uuid = NSUUID().uuidString
        self.skyflow.elementLookup[uuid] = skyflowElement
        skyflowElement.uuid = uuid
        Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "composable" : input.label], contextOptions: tempContextOptions)
        return skyflowElement
    }

    func on(eventName: EventName, handler: @escaping () -> Void) -> Void where T: ComposableContainer {
        if (eventName == EventName.SUBMIT){
            for element in elements {
                element.onSubmitHandler = handler
            }
        }
    }

    internal func createRows(from elements: [Int], numberOfRows: Int) -> [[Int]] {
        var number = Array(repeating: 0, count: elements.count)
        var result = [[Int]]()

        for i in 0..<elements.count {
            if i > 0 {
                number[i] = elements[i] + number[i-1]
            } else {
                number[i] = elements[i]
            }
        }
        for i in 0..<numberOfRows {
            var row = [Int]()
            for j in (0...elements[i]-1).reversed() {
                if number[i] == 1 {
                    row = [1]
                } else {
                    row.append(number[i] - j)
                }
            }
            result.append(row)
        }
        return result
    }
    internal func updateErrorMessageInLabel(errorList: [String], layout: [Int], labelArray: [UILabel], result:[[Int]]) -> [UILabel]{
        let labelArray = labelArray
        for j in 0..<layout.count {
            labelArray[j].text = concatenateStringArray(errorList, from: result[j][0]-1, to: result[j][result[j].count - 1] - 1)
        }
        return labelArray
   }
   internal func concatenateStringArray(_ array: [String], from startIndex: Int, to endIndex: Int) -> String {
        guard startIndex >= 0, startIndex < array.count,
              endIndex >= 0, endIndex < array.count, startIndex <= endIndex else {
            return ""
        }
        let subarray = array[startIndex...endIndex]

        let concatenatedString = subarray.joined(separator: "")

        return concatenatedString
    }
   internal func createDynamicViews(layout: [Int]) -> UIView {
        var errorList  = Array(repeating: "", count: elements.count)
        let parentView = UIView()
        var previousChildView: UIView? = nil
        var previousLabel: UILabel? = nil
        var labelArray: [UILabel] = (0..<layout.count).map { _ in UILabel() }
        let rowWiseError = createRows(from: layout, numberOfRows: layout.count)
        var elementCount = 0
        let layoutArray = layout

        for i in layoutArray.indices {
            let childView = UIView()
            labelArray[i] = UILabel()
            parentView.addSubview(childView)
            parentView.addSubview(labelArray[i])

            labelArray[i].translatesAutoresizingMaskIntoConstraints = false
            labelArray[i].textColor = containerOptions?.errorTextStyles?.base?.textColor ?? .none
            labelArray[i].font = containerOptions?.errorTextStyles?.base?.font ?? .none
            labelArray[i].textAlignment = containerOptions?.errorTextStyles?.base?.textAlignment ?? .left
            childView.translatesAutoresizingMaskIntoConstraints = false

            for j in 0..<layoutArray[i] {
                childView.addSubview(elements[elementCount])
                let padding = containerOptions?.styles?.base?.padding  ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                childView.layer.borderColor = containerOptions?.styles?.base?.borderColor?.cgColor ?? .none
                childView.layer.borderWidth = containerOptions?.styles?.base?.borderWidth ?? 0
                childView.layer.cornerRadius = containerOptions?.styles?.base?.cornerRadius ?? 0
                childView.bounds = childView.frame.inset(by: padding)
//                childView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
                if containerOptions?.styles?.base?.height != nil {
                    childView.heightAnchor.constraint(equalToConstant: (containerOptions?.styles?.base?.height)!).isActive = true
                }
                if containerOptions?.styles?.base?.width != nil {
                    childView.widthAnchor.constraint(equalToConstant: (containerOptions?.styles?.base?.width)!).isActive = true
                }

                elements[elementCount].translatesAutoresizingMaskIntoConstraints = false

                if layoutArray[i] > 1 && elementCount >= 1 && j > 0 {

                    elements[elementCount].leadingAnchor.constraint(equalTo: elements[elementCount-1].trailingAnchor, constant: 20.0).isActive = true
                    elements[elementCount].centerYAnchor.constraint(equalTo: childView.centerYAnchor).isActive = true

                } else if j == 0 {
                    elements[elementCount].centerYAnchor.constraint(equalTo: childView.centerYAnchor).isActive = true
                    elements[elementCount].leftAnchor.constraint(equalTo: childView.leftAnchor, constant: 6.0).isActive = true
                    elements[elementCount].leadingAnchor.constraint(equalTo: childView.leadingAnchor, constant: 6.0).isActive = true
                }
                elements[elementCount].topAnchor.constraint(equalTo: childView.topAnchor).isActive = true
                elements[elementCount].bottomAnchor.constraint(equalTo: childView.bottomAnchor).isActive = true

                for element in elements {
                    element.onFocusIsTrue = {
                        errorList[element.elements.count] = ""
                        labelArray = self.updateErrorMessageInLabel(errorList: errorList, layout: layout, labelArray: labelArray, result: rowWiseError)
                        labelArray[i].textColor = self.containerOptions?.errorTextStyles?.focus?.textColor ?? self.containerOptions?.errorTextStyles?.base?.textColor ?? .none
                        labelArray[i].font = self.containerOptions?.errorTextStyles?.focus?.font ?? self.containerOptions?.errorTextStyles?.base?.font ?? .none
                        labelArray[i].textAlignment = self.containerOptions?.errorTextStyles?.focus?.textAlignment ?? self.containerOptions?.errorTextStyles?.base?.textAlignment ?? .left
                   }

                    element.onEndEditing = {
                        if element.errorMessage.text == "" {
                            errorList[element.elements.count] = ""
                        } else {
                            errorList[element.elements.count] = element.errorMessage.text! + ". "
                        }
                        labelArray = self.updateErrorMessageInLabel(errorList: errorList, layout: layout, labelArray: labelArray, result: rowWiseError)
                    }
                    element.onBeginEditing = {
                        errorList[element.elements.count] = ""
                        labelArray = self.updateErrorMessageInLabel(errorList: errorList, layout: layout, labelArray: labelArray, result: rowWiseError)
                        if( element.elements.count + 1 < self.elements.count ){
                            if let elementFieldType = element.fieldType, ALLOWED_FOCUS_AUTO_SHIFT_ELEMENT_TYPES.contains(elementFieldType) && element.textField.isFirstResponder && (element.state.getState()["isValid"] as! Bool)  {
                                if(element.elements.count + 1 < self.elements.count){
                                    self.elements[element.elements.count + 1].textField.becomeFirstResponder()
                                }
                            }
                        }
                    }
                }
                elementCount += 1
            }

            childView.translatesAutoresizingMaskIntoConstraints = false
            childView.topAnchor.constraint(equalTo: previousLabel?.bottomAnchor ?? previousChildView?.bottomAnchor ?? parentView.topAnchor, constant: 10.0).isActive = true
            childView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor).isActive = true
            childView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor).isActive = true

            labelArray[i].translatesAutoresizingMaskIntoConstraints = false
            labelArray[i].leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 6.0).isActive = true
            labelArray[i].trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -6.0).isActive = true
            labelArray[i].topAnchor.constraint(equalTo: childView.bottomAnchor, constant: 5.0).isActive = true

            previousChildView = childView
            previousLabel = labelArray[i]

        }
        previousChildView?.trailingAnchor.constraint(equalTo: parentView.trailingAnchor).isActive = true
        parentView.bottomAnchor.constraint(equalTo: previousLabel?.bottomAnchor ?? previousChildView?.bottomAnchor ?? parentView.bottomAnchor, constant: 10.0).isActive = true

        return parentView
    }


    func getComposableView() throws -> UIView where T: ComposableContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .COMPOSABLE_CONTAINER
        var totalCount = 0

        if let options = containerOptions {
            if (options.layout.count == 0) {
                throw SkyflowError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "\(ErrorCodes.EMPTY_COMPOSABLE_LAYOUT_ARRAY().description)" ])
            }

            for i in 0..<(options.layout.count) {
                totalCount += (options.layout[i])
            }
        } else {
            throw SkyflowError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "\(ErrorCodes.MISSING_COMPOSABLE_CONTAINER_OPTIONS().description)" ])
        }
        if (elements.count < totalCount || totalCount < elements.count){
            throw SkyflowError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "\(ErrorCodes.MISMATCH_ELEMENT_COUNT_LAYOUT_SUM().description)" ])
        }

        let view = createDynamicViews(layout: (containerOptions?.layout)!)
        return view
    }
}
