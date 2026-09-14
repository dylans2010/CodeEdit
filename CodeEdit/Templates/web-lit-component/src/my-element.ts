import { LitElement, html, css } from 'lit';
import { customElement, property } from 'lit/decorators.js';

@customElement('my-element')
export class MyElement extends LitElement {
  @property() name = '{{PROJECT_NAME}}';
  static styles = css`p { color: #0284c7; font-family: sans-serif; }`;
  render() { return html`<p>Hello from &lt;${this.name}&gt; custom element!</p>`; }
}
