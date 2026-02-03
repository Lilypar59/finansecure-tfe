import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { ENVIRONMENT_CONFIG } from '../../config/environment.config';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent {
  loginForm: FormGroup;
  loading = false;
  error: string | null = null;
  submitted = false;
  websiteUrl = ENVIRONMENT_CONFIG.websiteUrl; // ✅ URL del website dinámico

  constructor(
    private formBuilder: FormBuilder,
    private router: Router,
    private authService: AuthService
  ) {
    this.loginForm = this.formBuilder.group({
      username: ['', [Validators.required, Validators.minLength(3)]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  get f() {
    return this.loginForm.controls;
  }

  onSubmit() {
    this.submitted = true;
    this.error = null;

    if (this.loginForm.invalid) {
      return;
    }

    this.loading = true;
    this.authService.login(this.loginForm.value).subscribe({
      next: (response) => {
        if (response.success) {
          this.router.navigate(['/dashboard']);
        } else {
          this.error = response.message || 'Error al iniciar sesión';
        }
        this.loading = false;
      },
      error: (err) => {
        console.error(err);
        this.error = err.error?.message || 'Error al conectar con el servidor';
        this.loading = false;
      }
    });
  }

  goToRegister() {
    this.router.navigate(['/register']);
  }

  /**
   * 🌍 Navega al sitio web de marketing/información
   * Usa la URL del entorno actual (localhost:3000 o AWS)
   */
  goToWebsite() {
    window.open(this.websiteUrl, '_blank');
  }
}
