import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { DashboardComponent } from './pages/dashboard/dashboard.component';

const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  // rutas básicas futuras
  { path: 'ingresos', loadChildren: () => import('./pages/ingresos/ingresos.module').then(m => m.IngresosModule) },
  { path: 'gastos', loadChildren: () => import('./pages/gastos/gastos.module').then(m => m.GastosModule) },
  { path: '**', redirectTo: 'dashboard' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
