use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn render_frame(time: f64) -> f64 {
    time.sin()
}
