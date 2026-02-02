import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { TransactionsService, Dashboard, Transaction } from '../../services/transactions.service';
import { AuthService, User } from '../../services/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {

  dashboard?: Dashboard;
  currentUser: User | null = null;
  loading = false;
  error?: string;

  constructor(
    private transactionsService: TransactionsService,
    private authService: AuthService,
    private router: Router
  ) {
    this.currentUser = this.authService.getCurrentUser();
  }

  ngOnInit(): void {
    if (!this.authService.isAuthenticated()) {
      this.router.navigate(['/login']);
      return;
    }
    this.loadDashboard();
  }

  loadDashboard(): void {
    this.loading = true;
    this.error = undefined;

    this.transactionsService.getDashboard().subscribe({
      next: (data) => {
        this.dashboard = data;
        this.loading = false;
      },
      error: (err) => {
        console.error(err);
        this.error = 'No se pudo cargar el resumen financiero.';
        this.loading = false;
      }
    });
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => {
        this.router.navigate(['/login']);
      },
      error: (err) => {
        console.error('Error al logout:', err);
        this.router.navigate(['/login']);
      }
    });
  }

  getTransactionIcon(type: string): string {
    switch (type?.toLowerCase()) {
      case 'income':
        return '↓';
      case 'expense':
        return '↑';
      default:
        return '→';
    }
  }

  getTransactionColor(type: string): string {
    switch (type?.toLowerCase()) {
      case 'income':
        return 'green';
      case 'expense':
        return 'red';
      default:
        return 'gray';
    }
  }
}


