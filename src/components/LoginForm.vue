<template>
  <div class="login-container">
    <div class="form-card">
      <h2>{{ isLogin ? '同学登录' : '同学注册' }}</h2>
      
      <!-- 邮箱输入框 -->
      <div class="input-group">
        <label>邮箱</label>
        <input 
          v-model="email" 
          type="email" 
          placeholder="请输入你的邮箱"
          @keyup.enter="handleSubmit"
        />
      </div>

      <!-- 密码输入框 -->
      <div class="input-group">
        <label>密码</label>
        <input 
          v-model="password" 
          type="password" 
          placeholder="请输入密码（至少6位）"
          @keyup.enter="handleSubmit"
        />
      </div>

      <!-- 操作按钮 -->
      <button class="submit-btn" @click="handleSubmit" :disabled="loading">
        {{ loading ? '处理中...' : (isLogin ? '登录' : '注册') }}
      </button>

      <!-- 切换登录/注册 -->
      <p class="toggle-text">
        {{ isLogin ? '还没有账号？' : '已有账号？' }}
        <a href="#" @click.prevent="toggleMode">
          {{ isLogin ? '立即注册' : '去登录' }}
        </a>
      </p>

      <!-- 错误提示 -->
      <div v-if="error" class="error-msg">{{ error }}</div>
      
      <!-- 成功提示 -->
      <div v-if="successMsg" class="success-msg">{{ successMsg }}</div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const router = useRouter()
// 状态变量
const email = ref('')
const password = ref('')
const isLogin = ref(true) // true=登录模式, false=注册模式
const loading = ref(false)
const error = ref('')
const successMsg = ref('')

// 切换登录/注册模式
const toggleMode = () => {
  isLogin.value = !isLogin.value
  error.value = ''
  successMsg.value = ''
  email.value = ''
  password.value = ''
}

// 处理提交
const handleSubmit = async () => {
  // 简单校验
  if (!email.value || !password.value) {
    error.value = '邮箱和密码都不能为空'
    return
  }
  if (password.value.length < 6) {
    error.value = '密码长度至少6位'
    return
  }

  loading.value = true
  error.value = ''
  successMsg.value = ''

  try {
    if (isLogin.value) {
      // ========== 登录逻辑 ==========
      const { data, error: loginError } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value
      })

      if (loginError) throw loginError

      successMsg.value = '登录成功！正在跳转...'

      setTimeout(() => {
        localStorage.setItem('user', JSON.stringify(data.user))
        router.push('/dashboard')
      }, 1000)

    } else {
      // ========== 注册逻辑 ==========
      const { data, error: signUpError } = await supabase.auth.signUp({
        email: email.value,
        password: password.value
      })

      if (signUpError) throw signUpError

      // 检查是否需要验证邮箱
      if (data.user?.identities?.length === 0) {
        error.value = '该邮箱已被注册，请直接登录'
      } else if (data.user && !data.user.email_confirmed_at) {
        // 邮箱验证开启的情况
        successMsg.value = '注册成功！请前往邮箱验证后登录'
        setTimeout(() => {
          isLogin.value = true
          password.value = ''
        }, 2000)
      } else {
        successMsg.value = '注册成功！已自动跳转到登录...'
        setTimeout(() => {
          isLogin.value = true
          password.value = ''
          successMsg.value = ''
        }, 1500)
      }
    }
  } catch (err) {
    error.value = err.message || '操作失败，请稍后重试'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.form-card {
  width: 100%;
  max-width: 400px;
  padding: 40px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
}

h2 {
  margin-bottom: 30px;
  text-align: center;
  color: #333;
}

.input-group {
  margin-bottom: 20px;
}

.input-group label {
  display: block;
  margin-bottom: 8px;
  color: #555;
  font-size: 14px;
}

.input-group input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 16px;
  box-sizing: border-box;
  transition: border-color 0.3s;
}

.input-group input:focus {
  outline: none;
  border-color: #667eea;
}

.submit-btn {
  width: 100%;
  padding: 14px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.3s;
}

.submit-btn:hover {
  background: #5a67d8;
}

.submit-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.toggle-text {
  margin-top: 20px;
  text-align: center;
  color: #666;
}

.toggle-text a {
  color: #667eea;
  text-decoration: none;
  font-weight: bold;
}

.toggle-text a:hover {
  text-decoration: underline;
}

.error-msg {
  margin-top: 16px;
  padding: 12px;
  background: #fee;
  border-radius: 8px;
  color: #c33;
  font-size: 14px;
}

.success-msg {
  margin-top: 16px;
  padding: 12px;
  background: #efe;
  border-radius: 8px;
  color: #3a3;
  font-size: 14px;
}
</style>