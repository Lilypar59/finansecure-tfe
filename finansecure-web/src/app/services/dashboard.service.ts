import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_CONFIG } from '../config/api.config';

export interface TransactionSummary {
  date: string;
  type: string;
  category: string;
  amount: number;
}

export interface DashboardSummary {
  period: string;
  totalIncome: number;
  totalExpenses: number;
  balance: number;
  recentTransactions: TransactionSummary[];
}

@Injectable({
  providedIn: 'root'
})
export class DashboardService {

  // ✅ CORRECTO: Usar ruta relativa a través del NGINX gateway
  // El NGINX enrutará /api/v1/transactions/* al servicio correcto
  private apiUrl = `${API_CONFIG.getTransactionsUrl()}/dashboard`;

  constructor(private http: HttpClient) { }

  getSummary(): Observable<DashboardSummary> {
    return this.http.get<DashboardSummary>(this.apiUrl);
  }
}

