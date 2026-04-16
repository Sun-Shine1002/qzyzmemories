<template>
  <div class="dashboard">
    <header class="header">
      <h1>同学录</h1>
      <div class="user-info">
        <span>{{ user?.email }}</span>
        <button @click="handleLogout" class="logout-btn">退出登录</button>
      </div>
    </header>

    <main class="main-content">
      <div class="tabs">
        <button
          :class="{ active: activeTab === '2025' }"
          @click="activeTab = '2025'"
        >
          2025届
        </button>
        <button
          :class="{ active: activeTab === '2026' }"
          @click="activeTab = '2026'"
        >
          2026届
        </button>
      </div>

      <div class="content-area">
        <div class="card">
          <h2>{{ activeTab === '2025' ? '2025届' : '2026届' }}同学信息</h2>

          <div v-if="loading" class="loading">加载中...</div>
          <div v-else-if="error" class="error-msg">{{ error }}</div>

          <div v-else class="user-profile">
            <div class="profile-header">
              <div class="avatar">{{ profile?.username?.charAt(0) || '?' }}</div>
              <div class="profile-title">
                <h3>{{ profile?.username || '未设置姓名' }}</h3>
                <p>{{ activeTab }}届</p>
              </div>
            </div>

            <div class="profile-form">
              <div class="form-group">
                <label>用户名</label>
                <input v-model="editForm.username" type="text" placeholder="请输入用户名" />
              </div>

              <div class="form-group">
                <label>毕业年份</label>
                <select v-model="editForm.graduation_year">
                  <option value="2025">2025届</option>
                  <option value="2026">2026届</option>
                </select>
              </div>

              <div class="form-group">
                <label>班级</label>
                <input v-model="editForm.class_name" type="text" placeholder="如：高三(1)班" />
              </div>

              <div class="form-group">
                <label>邮箱</label>
                <input :value="user?.email" type="text" disabled />
              </div>

              <div class="btn-group">
                <button @click="handleSave" :disabled="saving" class="save-btn">
                  {{ saving ? '保存中...' : '保存修改' }}
                </button>
                <button @click="handleReset" class="reset-btn">重置</button>
              </div>

              <div v-if="saveSuccess" class="success-msg">保存成功！</div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const router = useRouter()

const user = ref(null)
const profile = ref(null)
const activeTab = ref('2025')
const loading = ref(true)
const saving = ref(false)
const error = ref('')
const saveSuccess = ref(false)

const editForm = ref({
  username: '',
  graduation_year: '2025',
  class_name: ''
})

// 加载用户信息
const loadProfile = async () => {
  if (!user.value) return

  loading.value = true
  error.value = ''

  try {
    const { data, error: fetchError } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', user.value.id)
      .single()

    if (fetchError && fetchError.code !== 'PGRST116') {
      throw fetchError
    }

    profile.value = data

    if (data) {
      editForm.value = {
        username: data.username || '',
        graduation_year: data.graduation_year || '2025',
        class_name: data.class_name || ''
      }
      activeTab.value = data.graduation_year || '2025'
    }
  } catch (err) {
    error.value = err.message || '加载失败'
  } finally {
    loading.value = false
  }
}

// 保存用户信息
const handleSave = async () => {
  if (!editForm.value.username) {
    error.value = '用户名不能为空'
    return
  }

  saving.value = true
  error.value = ''
  saveSuccess.value = false

  try {
    const profileData = {
      user_id: user.value.id,
      username: editForm.value.username,
      graduation_year: editForm.value.graduation_year,
      class_name: editForm.value.class_name,
      updated_at: new Date().toISOString()
    }

    if (profile.value) {
      const { error: updateError } = await supabase
        .from('user_profiles')
        .update(profileData)
        .eq('user_id', user.value.id)

      if (updateError) throw updateError
    } else {
      const { error: insertError } = await supabase
        .from('user_profiles')
        .insert([profileData])

      if (insertError) throw insertError
    }

    profile.value = profileData
    saveSuccess.value = true
    setTimeout(() => { saveSuccess.value = false }, 2000)
  } catch (err) {
    error.value = err.message || '保存失败'
  } finally {
    saving.value = false
  }
}

// 重置表单
const handleReset = () => {
  if (profile.value) {
    editForm.value = {
      username: profile.value.username || '',
      graduation_year: profile.value.graduation_year || '2025',
      class_name: profile.value.class_name || ''
    }
  } else {
    editForm.value = {
      username: '',
      graduation_year: '2025',
      class_name: ''
    }
  }
}

// 退出登录
const handleLogout = async () => {
  await supabase.auth.signOut()
  localStorage.removeItem('user')
  router.push('/')
}

// 监听 tab 变化，更新毕业年份
watch(activeTab, (newTab) => {
  editForm.value.graduation_year = newTab
})

onMounted(async () => {
  const userData = localStorage.getItem('user')
  if (userData) {
    user.value = JSON.parse(userData)
    await loadProfile()
  } else {
    router.push('/')
  }
})
</script>

<style scoped>
.dashboard {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 40px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.header h1 {
  color: white;
  margin: 0;
  font-size: 24px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 20px;
}

.user-info span {
  color: white;
}

.logout-btn {
  padding: 8px 16px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.logout-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.main-content {
  padding: 40px;
  max-width: 800px;
  margin: 0 auto;
}

.tabs {
  display: flex;
  gap: 20px;
  margin-bottom: 30px;
}

.tabs button {
  flex: 1;
  padding: 16px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 2px solid transparent;
  border-radius: 12px;
  font-size: 16px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s;
}

.tabs button.active {
  background: white;
  color: #667eea;
  border-color: white;
}

.card {
  background: white;
  border-radius: 16px;
  padding: 40px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
}

.card h2 {
  margin-bottom: 30px;
  color: #333;
  text-align: center;
}

.loading, .error-msg {
  text-align: center;
  padding: 40px;
}

.error-msg {
  color: #c33;
  background: #fee;
  border-radius: 8px;
}

.user-profile {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.profile-header {
  display: flex;
  align-items: center;
  gap: 20px;
}

.avatar {
  width: 80px;
  height: 80px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 32px;
  font-weight: bold;
}

.profile-title h3 {
  margin: 0;
  color: #333;
  font-size: 24px;
}

.profile-title p {
  margin: 5px 0 0;
  color: #666;
}

.profile-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  color: #555;
  font-size: 14px;
  font-weight: 500;
}

.form-group input,
.form-group select {
  padding: 12px 16px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 0.3s;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #667eea;
}

.form-group input:disabled {
  background: #f5f5f5;
  color: #999;
}

.btn-group {
  display: flex;
  gap: 15px;
  margin-top: 10px;
}

.save-btn {
  flex: 1;
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

.save-btn:hover {
  background: #5a67d8;
}

.save-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.reset-btn {
  padding: 14px 24px;
  background: #f5f5f5;
  color: #666;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.3s;
}

.reset-btn:hover {
  background: #e0e0e0;
}

.success-msg {
  text-align: center;
  padding: 12px;
  background: #efe;
  border-radius: 8px;
  color: #3a3;
}
</style>