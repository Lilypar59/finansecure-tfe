import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { AuthService } from './auth.service';
import { API_CONFIG } from '../config/api.config';

export interface Transaction {
  id: string;
  type: string;
  category: string;
  description: string;
  amount: number;
  date: string;
  status: string;
}

export interface Dashboard {
  period: string;
  totalIncome: number;
  totalExpenses: number;
  balance: number;
  recentTransactions: Transaction[];
}

export interface CreateTransactionRequest {
  type: string;
  category: string;
  description: string;
  amount: number;
  date: string;
}

export interface Category {
  id: string;
  name: string;
  description: string;
}

export interface Budget {
  id: string;
  category: string;
  limit: number;
  spent: number;
  period: string;
}

@Injectable({
  providedIn: 'root'
})
export class TransactionsService {
  private apiUrl = API_CONFIG.getTransactionsUrl();

  constructor(
    private http: HttpClient,
    private authService: AuthService
  ) { }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getAccessToken();
    return new HttpHeaders({
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    });
  }

  // Dashboard endpoints
  getDashboard(): Observable<Dashboard> {
    // Datos mock mientras Transactions se habilita
    const mockDashboard: Dashboard = {
      period: new Date().toLocaleDateString(),
      totalIncome: 5000,
      totalExpenses: 2300,
      balance: 2700,
      recentTransactions: [
        {
          id: '1',
          type: 'income',
          category: 'Salary',
          description: 'Monthly salary',
          amount: 5000,
          date: new Date().toISOString(),
          status: 'completed'
        },
        {
          id: '2',
          type: 'expense',
          category: 'Groceries',
          description: 'Weekly groceries',
          amount: 150,
          date: new Date().toISOString(),
          status: 'completed'
        },
        {
          id: '3',
          type: 'expense',
          category: 'Utilities',
          description: 'Electric bill',
          amount: 80,
          date: new Date().toISOString(),
          status: 'completed'
        }
      ]
    };

    return of(mockDashboard);

    // Descomentar cuando Transactions API esté disponible:
    // return this.http.get<Dashboard>(`${this.apiUrl}/dashboard`, {
    //   headers: this.getHeaders()
    // });
  }

  // Transactions endpoints
  getTransactions(page: number = 1, pageSize: number = 10): Observable<any> {
    return this.http.get(`${this.apiUrl}/transactions?page=${page}&pageSize=${pageSize}`, {
      headers: this.getHeaders()
    });
  }

  getTransaction(id: string): Observable<Transaction> {
    return this.http.get<Transaction>(`${this.apiUrl}/transactions/${id}`, {
      headers: this.getHeaders()
    });
  }

  createTransaction(request: CreateTransactionRequest): Observable<Transaction> {
    return this.http.post<Transaction>(`${this.apiUrl}/transactions`, request, {
      headers: this.getHeaders()
    });
  }

  updateTransaction(id: string, request: CreateTransactionRequest): Observable<Transaction> {
    return this.http.put<Transaction>(`${this.apiUrl}/transactions/${id}`, request, {
      headers: this.getHeaders()
    });
  }

  deleteTransaction(id: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/transactions/${id}`, {
      headers: this.getHeaders()
    });
  }

  // Categories endpoints
  getCategories(): Observable<Category[]> {
    return this.http.get<Category[]>(`${this.apiUrl}/categories`, {
      headers: this.getHeaders()
    });
  }

  // Budgets endpoints
  getBudgets(): Observable<Budget[]> {
    return this.http.get<Budget[]>(`${this.apiUrl}/budgets`, {
      headers: this.getHeaders()
    });
  }

  createBudget(budget: any): Observable<Budget> {
    return this.http.post<Budget>(`${this.apiUrl}/budgets`, budget, {
      headers: this.getHeaders()
    });
  }

  updateBudget(id: string, budget: any): Observable<Budget> {
    return this.http.put<Budget>(`${this.apiUrl}/budgets/${id}`, budget, {
      headers: this.getHeaders()
    });
  }

  deleteBudget(id: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/budgets/${id}`, {
      headers: this.getHeaders()
    });
  }
}
