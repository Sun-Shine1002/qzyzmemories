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
      <div class="user-card" @click="showProfilePanel = true">
        <div class="user-avatar">
          {{ profile?.username?.charAt(0) || '?' }}
        </div>
        <div class="user-details">
          <h3>{{ profile?.username || '未设置姓名' }}</h3>
          <p>{{ profile?.class_name || '未设置班级' }}</p>
        </div>
        <span class="edit-hint">点击编辑</span>
      </div>

      <div class="modules-grid">
        <div class="module-card" @click="activeModule = '2025'">
          <div class="module-icon">🎓</div>
          <h2>2025届</h2>
          <p>查看同学信息</p>
          <span class="enter-btn">进入</span>
        </div>

        <div class="module-card" @click="activeModule = '2026'">
          <div class="module-icon">🎓</div>
          <h2>2026届</h2>
          <p>查看同学信息</p>
          <span class="enter-btn">进入</span>
        </div>
      </div>

      <!-- 2025届模块详情 -->
      <div v-if="activeModule === '2025'" class="module-detail">
        <div class="detail-header">
          <button class="back-btn" @click="activeModule = null">← 返回</button>
          <h2>2025届同学录</h2>
        </div>

        <div class="tabs">
          <button :class="{ active: detailTab === 'members' }" @click="detailTab = 'members'">
            同学信息
          </button>
          <button :class="{ active: detailTab === 'photos' }" @click="loadPhotos('2025')">
            相册
          </button>
        </div>

        <div v-if="detailTab === 'members'" class="members-list">
          <div v-if="loadingMembers" class="loading">加载中...</div>
          <div v-else-if="membersError" class="error-msg">{{ membersError }}</div>
          <div v-else-if="members.length === 0" class="empty-msg">暂无同学信息</div>
          <div v-else class="member-grid">
            <div v-for="member in members" :key="member.id" class="member-card">
              <div class="member-avatar">
                {{ member.username?.charAt(0) || '?' }}
              </div>
              <div class="member-info">
                <h4>{{ member.username }}</h4>
                <p>{{ member.class_name || '未设置班级' }}</p>
              </div>
            </div>
          </div>
        </div>

        <div v-if="detailTab === 'photos'" class="photos-section">
          <div v-if="loadingPhotos" class="loading">加载中...</div>
          <div v-else-if="photosError" class="error-msg">{{ photosError }}</div>
          <div v-else-if="photos.length === 0" class="empty-msg">
            <p>暂无相册</p>
            <p class="sub-text">即将开放上传功能</p>
          </div>
          <div v-else class="photo-grid">
            <div v-for="photo in photos" :key="photo.id" class="photo-item">
              <img :src="photo.url" :alt="photo.title" />
              <p>{{ photo.title }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- 2026届模块详情 -->
      <div v-if="activeModule === '2026'" class="module-detail">
        <div class="detail-header">
          <button class="back-btn" @click="activeModule = null">← 返回</button>
          <h2>2026届同学录</h2>
        </div>

        <div class="tabs">
          <button :class="{ active: detailTab === 'members' }" @click="detailTab = 'members'">
            同学信息
          </button>
          <button :class="{ active: detailTab === 'photos' }" @click="loadPhotos('2026')">
            相册
          </button>
        </div>

        <div v-if="detailTab === 'members'" class="members-list">
          <div v-if="loadingMembers" class="loading">加载中...</div>
          <div v-else-if="membersError" class="error-msg">{{ membersError }}</div>
          <div v-else-if="members.length === 0" class="empty-msg">暂无同学信息</div>
          <div v-else class="member-grid">
            <div v-for="member in members" :key="member.id" class="member-card">
              <div class="member-avatar">
                {{ member.username?.charAt(0) || '?' }}
              </div>
              <div class="member-info">
                <h4>{{ member.username }}</h4>
                <p>{{ member.class_name || '未设置班级' }}</p>
              </div>
            </div>
          </div>
        </div>

        <div v-if="detailTab === 'photos'" class="photos-section">
          <div v-if="loadingPhotos" class="loading">加载中...</div>
          <div v-else-if="photosError" class="error-msg">{{ photosError }}</div>
          <div v-else-if="photos.length === 0" class="empty-msg">
            <p>暂无相册</p>
            <p class="sub-text">即将开放上传功能</p>
          </div>
          <div v-else class="photo-grid">
            <div v-for="photo in photos" :key="photo.id" class="photo-item">
              <img :src="photo.url" :alt="photo.title" />
              <p>{{ photo.title }}</p>
            </div>
          </div>
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
const activeModule = ref(null)
const detailTab = ref('members')

const loadingMembers = ref(false)
const membersError = ref('')
const members = ref([])

const loadingPhotos = ref(false)
const photosError = ref('')
const photos = ref([])

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

const loadMembers = async (year) => {
  loadingMembers.value = true
  membersError.value = ''
  members.value = []

  try {
    const { data, error } = await supabase
      .from('user_profiles')
      .select('id, username, class_name, graduation_year')
      .eq('graduation_year', year)

    if (error) throw error

    members.value = data || []
  } catch (err) {
    membersError.value = err.message || '加载失败'
  } finally {
    loadingMembers.value = false
  }
}

const loadPhotos = async (year) => {
  detailTab.value = 'photos'
  loadingPhotos.value = true
  photosError.value = ''
  photos.value = []

  try {
    const { data, error } = await supabase
      .from('photos')
      .select('*')
      .eq('graduation_year', year)

    if (error) throw error

    photos.value = data || []
  } catch (err) {
    photosError.value = err.message || '加载失败'
  } finally {
    loadingPhotos.value = false
  }
}

const handleProfileUpdate = (data) => {
  profile.value = { ...profile.value, ...data }
}

const handleLogout = async () => {
  await supabase.auth.signOut()
  localStorage.removeItem('user')
  router.push('/')
}

onMounted(async () => {
  const userData = localStorage.getItem('user')
  if (userData) {
    user.value = JSON.parse(userData)
    await loadProfile()
    await loadMembers('2025')
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
}

.main-content {
  padding: 40px;
  max-width: 900px;
  margin: 0 auto;
}

.user-card {
  background: white;
  border-radius: 16px;
  padding: 24px;
  margin-bottom: 30px;
  display: flex;
  align-items: center;
  gap: 20px;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.user-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.user-avatar {
  width: 60px;
  height: 60px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 24px;
  font-weight: bold;
}

.user-details {
  flex: 1;
}

.user-details h3 {
  margin: 0 0 5px;
  color: #333;
}

.user-details p {
  margin: 0;
  color: #666;
  font-size: 14px;
}

.edit-hint {
  color: #667eea;
  font-size: 14px;
}

.modules-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.module-card {
  background: white;
  border-radius: 16px;
  padding: 40px 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.module-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.2);
}

.module-icon {
  font-size: 60px;
  margin-bottom: 20px;
}

.module-card h2 {
  margin: 0 0 10px;
  color: #333;
}

.module-card p {
  margin: 0 0 20px;
  color: #666;
}

.enter-btn {
  display: inline-block;
  padding: 8px 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 20px;
  font-size: 14px;
}

.module-detail {
  background: white;
  border-radius: 16px;
  padding: 30px;
  margin-top: 30px;
}

.detail-header {
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 30px;
}

.back-btn {
  padding: 8px 16px;
  background: #f5f5f5;
  color: #666;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}

.detail-header h2 {
  margin: 0;
  color: #333;
}

.tabs {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.tabs button {
  padding: 10px 24px;
  background: #f5f5f5;
  color: #666;
  border: none;
  border-radius: 8px;
  cursor: pointer;
}

.tabs button.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.loading, .error-msg, .empty-msg {
  text-align: center;
  padding: 40px;
  color: #666;
}

.sub-text {
  font-size: 14px;
  color: #999;
  margin-top: 10px;
}

.member-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 15px;
}

.member-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 15px;
  background: #f9f9f9;
  border-radius: 12px;
}

.member-avatar {
  width: 50px;
  height: 50px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 18px;
  font-weight: bold;
}

.member-info h4 {
  margin: 0 0 5px;
  color: #333;
}

.member-info p {
  margin: 0;
  color: #666;
  font-size: 13px;
}

.photo-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 15px;
}

.photo-item {
  text-align: center;
}

.photo-item img {
  width: 100%;
  height: 150px;
  object-fit: cover;
  border-radius: 8px;
}

.photo-item p {
  margin: 8px 0 0;
  color: #666;
  font-size: 14px;
}
</style>