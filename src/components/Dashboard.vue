<template>
  <div class="dashboard">
    <header class="header">
      <h1>一中游记</h1>
      <div v-if="user" class="user-section">
        <div class="user-info">
          <div class="user-avatar">{{ profile?.username?.charAt(0) || '?' }}</div>
          <span class="user-name">{{ profile?.username || '未登录' }}</span>
        </div>
        <div class="user-actions">
          <button class="action-btn" @click="showProfilePanel = true">修改信息</button>
          <button class="action-btn logout-btn" @click="handleLogout">退出登录</button>
        </div>
      </div>
      <button v-else class="login-btn" @click="goToLogin">登录</button>
    </header>

    <main class="main-content">
      <!-- 年份选择 -->
      <div class="year-tabs">
        <button :class="{ active: activeYear === '2025' }" @click="activeYear = '2025'">
          2025届
        </button>
        <button :class="{ active: activeYear === '2026' }" @click="activeYear = '2026'">
          2026届
        </button>
      </div>

      <div class="modules-grid">
        <div class="module-card" @click="goToMemoir(activeYear)">
          <h2>{{ activeYear }}回忆录</h2>
          <p>点击进入</p>
        </div>
      </div>

      <!-- 提示信息 -->
      <p class="browse-hint">未登录用户可以浏览回忆录，登录后可参与评论</p>
    </main>

    <!-- 用户信息编辑面板 -->
    <ProfilePanel
      v-if="showProfilePanel && user"
      :user="user"
      :profile="profile"
      @close="showProfilePanel = false"
      @update="handleProfileUpdate"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'
import ProfilePanel from './ProfilePanel.vue'

const router = useRouter()

const user = ref(null)
const profile = ref(null)
const showProfilePanel = ref(false)
const activeYear = ref('2025')

const goToLogin = () => {
  router.push('/')
}

const loadProfile = async () => {
  if (!user.value) return

  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', user.value.id)
      .single()

    if (error && error.code !== 'PGRST116') {
      throw error
    }

    profile.value = data
  } catch (err) {
    console.error('加载profile失败:', err)
  }
}

const goToMemoir = (year) => {
  router.push(`/memoir/${year}`)
}

const handleProfileUpdate = (data) => {
  profile.value = { ...profile.value, ...data }
}

const handleLogout = async () => {
  if (!confirm('确定要退出登录吗？')) return

  localStorage.removeItem('user')
  const { error } = await supabase.auth.signOut()
  if (error) {
    console.error('退出登录失败:', error)
  }
  user.value = null
  profile.value = null
  router.push('/')
}

onMounted(async () => {
  const userData = localStorage.getItem('user')
  if (userData) {
    user.value = JSON.parse(userData)
    await loadProfile()
  }
})
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

.dashboard {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  flex-direction: column;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 40px;
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(15px);
}

.header h1 {
  color: white;
  margin: 0;
  font-size: 32px;
  letter-spacing: 6px;
  font-weight: bold;
}

.user-section {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 10px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  padding: 6px 14px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 15px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s;
}

.action-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.logout-btn {
  background: rgba(255, 100, 100, 0.3);
  border-color: rgba(255, 100, 100, 0.4);
}

.logout-btn:hover {
  background: rgba(255, 100, 100, 0.5);
}

.user-avatar {
  width: 40px;
  height: 40px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 18px;
  font-weight: bold;
}

.user-name {
  color: white;
  font-size: 15px;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
}

.year-tabs {
  display: flex;
  gap: 30px;
  margin-bottom: 50px;
}

.year-tabs button {
  padding: 16px 60px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 3px solid transparent;
  border-radius: 30px;
  font-size: 22px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s;
}

.year-tabs button.active {
  background: white;
  color: #667eea;
  border-color: rgba(255, 255, 255, 0.5);
}

.modules-grid {
  display: flex;
  gap: 50px;
}

.module-card {
  width: 350px;
  padding: 60px 50px;
  background: white;
  border-radius: 24px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 15px 50px rgba(0, 0, 0, 0.2);
}

.module-card:hover {
  transform: translateY(-12px);
  box-shadow: 0 25px 70px rgba(0, 0, 0, 0.3);
}

.module-card h2 {
  margin: 0 0 12px;
  color: #333;
  font-size: 32px;
}

.module-card p {
  margin: 0;
  color: #667eea;
  font-size: 16px;
}

.login-btn {
  padding: 10px 24px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 2px solid rgba(255, 255, 255, 0.5);
  border-radius: 20px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
}

.login-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.browse-hint {
  margin-top: 30px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
}

/* 手机适配 */
@media (max-width: 600px) {
  .header {
    padding: 15px 20px;
    flex-wrap: wrap;
  }

  .header h1 {
    font-size: 22px;
    letter-spacing: 3px;
  }

  .user-section {
    width: 100%;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
    margin-top: 12px;
  }

  .user-info {
    gap: 8px;
  }

  .user-avatar {
    width: 35px;
    height: 35px;
    font-size: 15px;
  }

  .user-name {
    font-size: 13px;
  }

  .user-actions {
    gap: 6px;
  }

  .action-btn {
    padding: 5px 12px;
    font-size: 11px;
  }

  .login-btn {
    padding: 8px 18px;
    font-size: 13px;
  }

  .main-content {
    padding: 30px 15px;
  }

  .year-tabs {
    flex-direction: column;
    gap: 15px;
    margin-bottom: 30px;
  }

  .year-tabs button {
    padding: 14px 50px;
    font-size: 18px;
  }

  .module-card {
    width: 280px;
    padding: 40px 30px;
  }

  .module-card h2 {
    font-size: 26px;
  }

  .module-card p {
    font-size: 14px;
  }

  .browse-hint {
    font-size: 13px;
    padding: 0 20px;
    text-align: center;
  }
}
</style>