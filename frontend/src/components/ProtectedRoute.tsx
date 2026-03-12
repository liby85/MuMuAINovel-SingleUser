"""
保护路由组件 - 单用户模式
"""
import type { ReactNode } from 'react';

interface ProtectedRouteProps {
  children: ReactNode;
}

export default function ProtectedRoute({ children }: ProtectedRouteProps) {
  // 在单用户模式下，直接渲染子组件，无需任何认证检查
  return <>{children}</>;
}
