use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn greet_name(name: &str) -> String {
    format!("Hello, {}! Powered by {{PROJECT_NAME}} WebAssembly.", name)
}
