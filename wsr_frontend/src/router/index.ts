import {
  createRouter,
  createWebHistory,
  RouteRecordRaw,
  NavigationGuardNext,
  RouteLocationNormalized,
} from "vue-router";

// Import portal-specific routes
import adminRoutes from "../admin_portal/router";
import companyRoutes from "../company_portal/router";
import employeeRoutes from "../employee_portal/router";

// Lazy-load views for better performance
const LoginView = () => import("../views/LoginView.vue");
const PortalLayout = () => import("../views/PortalLayout.vue");
const NotFound = () => import("../views/NotFound.vue");

// Define route meta type
interface Meta {
  requiresAuth?: boolean;
  role?: "admin" | "company" | "employee";
  [key: string]: unknown;
  [key: symbol]: unknown;
}

// Define routes with TypeScript support
const routes: Array<RouteRecordRaw> = [
  {
    path: "/",
    name: "Login",
    component: LoginView,
  },
  {
    path: "/admin",
    name: "AdminPortal",
    component: PortalLayout,
    meta: { requiresAuth: true, role: "admin" } as Meta,
  },
  {
    path: "/company",
    name: "CompanyPortal",
    component: PortalLayout,
    meta: { requiresAuth: true, role: "company" } as Meta,
  },
  {
    path: "/employee",
    name: "EmployeePortal",
    component: PortalLayout,
    meta: { requiresAuth: true, role: "employee" } as Meta,
  },
  {
    path: "/:pathMatch(.*)*",
    name: "NotFound",
    component: NotFound,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// 🚀 Role-Based Navigation Guards
router.beforeEach(
  (
    to: RouteLocationNormalized,
    from: RouteLocationNormalized,
    next: NavigationGuardNext
  ) => {
  const userRole = localStorage.getItem("userRole") as  
    | "admin"
    | "company"
    | "employee"
    | null;
  const isAuthenticated = !!userRole;

  if (to.meta.requiresAuth) {
    if (!isAuthenticated) {
      next("/"); // Redirect to login if not authenticated
    } else if (to.meta.role && to.meta.role !== userRole) {
      next("/"); // Redirect unauthorized users to login
    } else {
      next(); // Proceed if authenticated and role matches
    }
  } else {
    next(); // Allow public routes
  }
});

export default router;
