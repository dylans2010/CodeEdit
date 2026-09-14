import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-root',
  standalone: true,
  template: `
    <div style="text-align: center; padding: 3rem; font-family: sans-serif;">
      <h1>{{PROJECT_NAME}}</h1>
      <button (click)="increment()">Count: {{ count() }}</button>
    </div>
  `
})
export class AppComponent {
  count = signal(0);
  increment() { this.count.update(c => c + 1); }
}
