<template>
  <div class="login-container">
    <div class="form-card">
      <h2>{{ isLogin ? '同学登录' : '同学注册' }}</h2>

      <div class="input-group">
        <label>邮箱</label>
        <input
          v-model="email"
          type="email"
          placeholder="请输入你的邮箱"
          @keyup.enter="handleSubmit"
        />
      </div>

      <div class="input-group">
        <label>密码</label>
        <input
          v-model="password"
          type="password"
          placeholder="请输入密码（至少6位）"
          @keyup.enter="handleSubmit"
        />
      </div>

      <button class="submit-btn" @click="handleSubmit" :disabled="loading">
        {{ loading ? '处理中...' : (isLogin ? '登录' : '注册') }}
      </button>

      <p class="toggle-text">
        {{ isLogin ? '还没有账号？' : '已有账号？' }}
        <a href="#" @click.prevent="toggleMode">
          {{ isLogin ? '立即注册' : '去登录' }}
        </a>
      </p>

      <button class="back-btn" @click="goBack">返回浏览</button>

      <div v-if="error" class="error-msg">{{ error }}</div>
      <div v-if="successMsg" class="success-msg">{{ successMsg }}</div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const router = useRouter()

const email = ref('')
const password = ref('')
const isLogin = ref(true)
const loading = ref(false)
const error = ref('')
const successMsg = ref('')

onMounted(() => {
  // 如果已登录，直接跳转
  const userData = localStorage.getItem('user')
  if (userData) {
    router.push('/dashboard')
  }
})

const toggleMode = () => {
  isLogin.value = !isLogin.value
  error.value = ''
  successMsg.value = ''
  email.value = ''
  password.value = ''
}

const goBack = () => {
  router.push('/dashboard')
}

const handleSubmit = async () => {
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
      const { data, error: signUpError } = await supabase.auth.signUp({
        email: email.value,
        password: password.value
      })

      if (signUpError) throw signUpError

      if (data.user?.identities?.length === 0) {
        error.value = '该邮箱已被注册，请直接登录'
      } else if (data.user && !data.user.email_confirmed_at) {
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
* {
  box-sizing: border-box;
}

html, body {
  margin: 0;
  padding: 0;
  height: 100%;
}

.login-container {
  min-height: 100vh;
  min-height: 100dvh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}

.form-card {
  width: 100%;
  max-width: 420px;
  padding: 40px;
  background: white;
  border-radius: 24px;
  box-shadow: 0 25px 80px rgba(0, 0, 0, 0.2);
}

h2 {
  margin: 0 0 35px;
  text-align: center;
  color: #333;
  font-size: 28px;
  letter-spacing: 2px;
}

.input-group {
  margin-bottom: 22px;
}

.input-group label {
  display: block;
  margin-bottom: 10px;
  color: #555;
  font-size: 14px;
  font-weight: 500;
}

.input-group input {
  width: 100%;
  padding: 16px 18px;
  border: 2px solid #eee;
  border-radius: 12px;
  font-size: 16px;
  transition: border-color 0.3s;
}

.input-group input:focus {
  outline: none;
  border-color: #667eea;
}

.submit-btn {
  width: 100%;
  padding: 18px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 17px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s;
  margin-top: 15px;
  letter-spacing: 2px;
}

.submit-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
}

.submit-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.toggle-text {
  margin-top: 30px;
  text-align: center;
  color: #666;
  font-size: 14px;
}

.toggle-text a {
  color: #667eea;
  text-decoration: none;
  font-weight: bold;
}

.toggle-text a:hover {
  text-decoration: underline;
}

.back-btn {
  width: 100%;
  padding: 14px;
  margin-top: 20px;
  background: transparent;
  color: #667eea;
  border: 2px solid #667eea;
  border-radius: 12px;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.3s;
}

.back-btn:hover {
  background: rgba(102, 126, 234, 0.1);
}

.error-msg {
  margin-top: 25px;
  padding: 16px;
  background: #ffebee;
  border-radius: 12px;
  color: #c62828;
  font-size: 14px;
  text-align: center;
}

.success-msg {
  margin-top: 25px;
  padding: 16px;
  background: #e8f5e9;
  border-radius: 12px;
  color: #2e7d32;
  font-size: 14px;
  text-align: center;
}

/* 手机适配 */
@media (max-width: 600px) {
  .form-card {
    padding: 30px 25px;
  }

  h2 {
    font-size: 24px;
    margin-bottom: 30px;
  }

  .input-group {
    margin-bottom: 18px;
  }

  .input-group input {
    padding: 14px 16px;
    font-size: 15px;
  }

  .submit-btn {
    padding: 16px;
    font-size: 16px;
  }
}
</style>