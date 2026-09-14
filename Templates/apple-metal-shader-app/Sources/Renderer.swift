import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice

    init?(view: MTKView) {
        guard let dev = MTLCreateSystemDefaultDevice() else { return nil }
        self.device = dev
        super.init()
        view.device = dev
        view.delegate = self
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor else { return }
        rpd.colorAttachments[0].clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
    }
}
