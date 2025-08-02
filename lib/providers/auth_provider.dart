import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? error;

  AuthState({
    required this.status,
    this.user,
    this.token,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null && token != null;
  bool get isLoading => status == AuthStatus.loading;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(status: AuthStatus.loading)) {
    _checkAuthStatus();
  }

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  Future<void> _checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        ApiService.setToken(token);
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          final user = User.fromJson(userMap);
          
          // 验证token是否仍然有效
          final response = await ApiService.getProfile();
          
          if (response.isSuccess && response.data != null) {
            final updatedUser = User.fromJson(response.data!);
            state = AuthState(
              status: AuthStatus.authenticated,
              user: updatedUser,
              token: token,
            );
          } else {
            await _clearAuthData();
            state = AuthState(status: AuthStatus.unauthenticated);
          }
        } catch (e) {
          await _clearAuthData();
          state = AuthState(status: AuthStatus.unauthenticated);
        }
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      await _clearAuthData();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: '认证检查失败: $e',
      );
    }
  }

  Future<bool> login(String email, String code) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    
    try {
      final response = await ApiService.login(email, code);
      
      if (response.isSuccess && response.data != null) {
        final loginResponse = LoginResponse.fromJson(response.data!);
        
        await _saveAuthData(loginResponse.token, loginResponse.user);
        ApiService.setToken(loginResponse.token);
        
        state = AuthState(
          status: AuthStatus.authenticated,
          user: loginResponse.user,
          token: loginResponse.token,
        );
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: '登录失败: $e',
      );
      return false;
    }
  }

  Future<bool> register(String email, String code) async {
    try {
      final response = await ApiService.register(email, code);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendCode(String email) async {
    try {
      final response = await ApiService.sendCode(email);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await ApiService.verifyEmail(email, code);
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      await ApiService.logout();
    } catch (e) {
      // 即使logout请求失败，也要清除本地数据
    }
    
    await _clearAuthData();
    ApiService.setToken(null);
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});