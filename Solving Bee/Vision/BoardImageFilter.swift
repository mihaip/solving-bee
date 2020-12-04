import CoreImage
import CoreImage.CIFilterBuiltins

class BoardImageFilter: CIFilter {
    var inputImage: CIImage?

    private static let kernel: CIKernel = {
        guard let url = Bundle.main.url(forResource: "default", withExtension: "metallib"), let data = try? Data(contentsOf: url) else {
            fatalError("Unable to load metallib")
        }
        let name = "boardImageKernel"
        guard let kernel = try? CIKernel(functionName: name, fromMetalLibraryData: data) else {
            fatalError("Unable to create the CIColorKernel for filter \(name)")
        }
        return kernel
    }()

    override public var outputImage: CIImage? {
        guard let inputImage = inputImage else { return .none }
        return BoardImageFilter.kernel.apply(
            extent: inputImage.extent,
            roiCallback: {(index, rect) -> CGRect in return rect},
            arguments: [inputImage]
        )
    }
}
