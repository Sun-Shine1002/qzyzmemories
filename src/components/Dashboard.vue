<template>
  <div class="dashboard">
    <header class="header">
      <h1>一中游记</h1>
      <div class="user-mini" @click="showProfilePanel = true">
        <div class="user-avatar">{{ profile?.username?.charAt(0) || '?' }}</div>
      </div>
    </header>

    <main class="main-content">
      <!-- 年份选择 -->
      <div class="year-tabs">
        <button :class="{ active: activeYear === '2025' }" @click="activeYear = '2025'">
          2025
        </button>
        <button :class="{ active: activeYear === '2026' }" @click="activeYear = '2026'">
          2026
        </button>
      </div>

      <div class="modules-grid">
        <div class="module-card" @click="goToMemoir(activeYear)">
          <h2>进入{{ activeYear }}回忆录</h2>
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
  justify-content: center;
  align-items: center;
  padding: 20px 30px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  position: relative;
}

.header h1 {
  color: white;
  margin: 0;
  font-size: 28px;
  letter-spacing: 4px;
}

.user-mini {
  position: absolute;
  right: 30px;
  cursor: pointer;
}

.user-avatar {
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.9);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #667eea;
  font-size: 18px;
  font-weight: bold;
  transition: transform 0.3s;
}

.user-mini:hover .user-avatar {
  transform: scale(1.1);
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px;
}

.year-tabs {
  display: flex;
  gap: 20px;
  margin-bottom: 30px;
}

.year-tabs button {
  padding: 12px 40px;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  border: 2px solid transparent;
  border-radius: 25px;
  font-size: 18px;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s;
}

.year-tabs button.active {
  background: white;
  color: #667eea;
}

.modules-grid {
  display: flex;
  gap: 40px;
}

.module-card {
  width: 280px;
  padding: 40px;
  background: white;
  border-radius: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
}

.module-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.25);
}

.module-card h2 {
  margin: 0 0 10px;
  color: #333;
  font-size: 24px;
}

.module-card p {
  margin: 0;
  color: #667eea;
  font-size: 14px;
}
</style>