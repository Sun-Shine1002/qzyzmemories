<template>
  <div class="dashboard">
    <header class="header">
      <h1>一中游记</h1>
      <div class="user-mini" @click="showProfilePanel = true">
        <div class="user-avatar">{{ profile?.username?.charAt(0) || '?' }}</div>
        <span class="user-name">{{ profile?.username || '未登录' }}</span>
      </div>
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
    </main>

    <!-- 用户信息编辑面板 -->
    <ProfilePanel
      v-if="showProfilePanel"
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
  display: flex;
  flex-direction: column;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 60px;
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(15px);
}

.header h1 {
  color: white;
  margin: 0;
  font-size: 36px;
  letter-spacing: 8px;
  font-weight: bold;
}

.user-mini {
  display: flex;
  align-items: center;
  gap: 15px;
  cursor: pointer;
  padding: 10px 20px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 30px;
  transition: all 0.3s;
}

.user-mini:hover {
  background: rgba(255, 255, 255, 0.2);
}

.user-avatar {
  width: 45px;
  height: 45px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 20px;
  font-weight: bold;
}

.user-name {
  color: white;
  font-size: 16px;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px;
}

.year-tabs {
  display: flex;
  gap: 40px;
  margin-bottom: 60px;
}

.year-tabs button {
  padding: 20px 80px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 3px solid transparent;
  border-radius: 30px;
  font-size: 24px;
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
  gap: 60px;
}

.module-card {
  width: 400px;
  padding: 80px 60px;
  background: white;
  border-radius: 30px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
}

.module-card:hover {
  transform: translateY(-15px);
  box-shadow: 0 30px 80px rgba(0, 0, 0, 0.3);
}

.module-card h2 {
  margin: 0 0 15px;
  color: #333;
  font-size: 36px;
}

.module-card p {
  margin: 0;
  color: #667eea;
  font-size: 18px;
}
</style>