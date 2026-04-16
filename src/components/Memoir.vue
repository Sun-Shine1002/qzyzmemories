<template>
  <div class="memoir-page">
    <header class="header">
      <button class="back-btn" @click="router.push('/dashboard')">← 返回</button>
      <h1>{{ year }}回忆录</h1>
      <div class="user-mini">
        <span>{{ user?.email }}</span>
      </div>
    </header>

    <main class="main-content">
      <div class="tabs">
        <button :class="{ active: activeTab === 'comments' }" @click="activeTab = 'comments'">
          回忆墙
        </button>
        <button :class="{ active: activeTab === 'photos' }" @click="loadPhotos">
          相册
        </button>
      </div>

      <!-- 回忆墙 -->
      <div v-if="activeTab === 'comments'" class="comments-section">
        <div class="comment-form">
          <textarea
            v-model="newComment"
            placeholder="写下你的回忆..."
            rows="3"
          ></textarea>
          <button @click="submitComment" :disabled="submitting" class="submit-btn">
            {{ submitting ? '发布中...' : '发布' }}
          </button>
        </div>

        <div v-if="loadingComments" class="loading">加载中...</div>
        <div v-else-if="commentsError" class="error-msg">{{ commentsError }}</div>
        <div v-else-if="comments.length === 0" class="empty-msg">
          <p>暂无回忆</p>
          <p class="sub-text">成为第一个分享回忆的人吧！</p>
        </div>
        <div v-else class="comments-list">
          <div v-for="comment in comments" :key="comment.id" class="comment-card">
            <div class="comment-header">
              <div class="comment-avatar">{{ comment.username?.charAt(0) || '?' }}</div>
              <div class="comment-meta">
                <span class="comment-author">{{ comment.username }}</span>
                <span class="comment-time">{{ formatTime(comment.created_at) }}</span>
              </div>
            </div>
            <div class="comment-content">{{ comment.content }}</div>
          </div>
        </div>
      </div>

      <!-- 相册 -->
      <div v-if="activeTab === 'photos'" class="photos-section">
        <div class="upload-form">
          <input v-model="photoTitle" type="text" placeholder="图片标题" />
          <input v-model="photoUrl" type="text" placeholder="图片地址" />
          <button @click="uploadPhoto" :disabled="uploading" class="submit-btn">
            {{ uploading ? '上传中...' : '上传' }}
          </button>
        </div>

        <div v-if="loadingPhotos" class="loading">加载中...</div>
        <div v-else-if="photosError" class="error-msg">{{ photosError }}</div>
        <div v-else-if="photos.length === 0" class="empty-msg">
          <p>暂无相册</p>
          <p class="sub-text">分享你的照片吧！</p>
        </div>
        <div v-else class="photo-grid">
          <div v-for="photo in photos" :key="photo.id" class="photo-item">
            <img :src="photo.url" :alt="photo.title" />
            <p>{{ photo.title }}</p>
            <span class="photo-time">{{ formatTime(photo.created_at) }}</span>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

const route = useRoute()
const router = useRouter()

const year = route.params.year || '2025'
const user = ref(null)
const activeTab = ref('comments')

const newComment = ref('')
const submitting = ref(false)
const loadingComments = ref(false)
const commentsError = ref('')
const comments = ref([])

const photoTitle = ref('')
const photoUrl = ref('')
const uploading = ref(false)
const loadingPhotos = ref(false)
const photosError = ref('')
const photos = ref([])

const loadComments = async () => {
  loadingComments.value = true
  commentsError.value = ''

  try {
    const { data: commentsData, error } = await supabase
      .from('comments')
      .select('*')
      .eq('graduation_year', year)
      .order('created_at', { ascending: false })

    if (error) throw error

    // 获取用户信息
    const userIds = commentsData.map(c => c.user_id)
    const { data: profilesData } = await supabase
      .from('user_profiles')
      .select('user_id, username')
      .in('user_id', userIds)

    const profileMap = {}
    profilesData?.forEach(p => { profileMap[p.user_id] = p.username })

    comments.value = commentsData.map(c => ({
      ...c,
      username: profileMap[c.user_id] || '未知用户'
    }))
  } catch (err) {
    commentsError.value = err.message || '加载失败'
  } finally {
    loadingComments.value = false
  }
}

const submitComment = async () => {
  if (!newComment.value.trim()) return

  submitting.value = true

  try {
    const { error } = await supabase
      .from('comments')
      .insert([
        {
          user_id: user.value.id,
          graduation_year: year,
          content: newComment.value.trim()
        }
      ])

    if (error) throw error

    newComment.value = ''
    await loadComments()
  } catch (err) {
    alert(err.message || '发布失败')
  } finally {
    submitting.value = false
  }
}

const loadPhotos = async () => {
  activeTab.value = 'photos'
  loadingPhotos.value = true
  photosError.value = ''

  try {
    const { data, error } = await supabase
      .from('photos')
      .select('*')
      .eq('graduation_year', year)
      .order('created_at', { ascending: false })

    if (error) throw error

    photos.value = data || []
  } catch (err) {
    photosError.value = err.message || '加载失败'
  } finally {
    loadingPhotos.value = false
  }
}

const uploadPhoto = async () => {
  if (!photoTitle.value.trim() || !photoUrl.value.trim()) return

  uploading.value = true

  try {
    const { error } = await supabase
      .from('photos')
      .insert([
        {
          graduation_year: year,
          title: photoTitle.value.trim(),
          url: photoUrl.value.trim()
        }
      ])

    if (error) throw error

    photoTitle.value = ''
    photoUrl.value = ''
    await loadPhotos()
  } catch (err) {
    alert(err.message || '上传失败')
  } finally {
    uploading.value = false
  }
}

const formatTime = (time) => {
  if (!time) return ''
  const d = new Date(time)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

onMounted(async () => {
  const userData = localStorage.getItem('user')
  if (userData) {
    user.value = JSON.parse(userData)
    await loadComments()
  } else {
    router.push('/')
  }
})
</script>

<style scoped>
.memoir-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.header {
  display: flex;
  align-items: center;
  padding: 15px 30px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.back-btn {
  padding: 8px 16px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  margin-right: 20px;
}

.header h1 {
  flex: 1;
  color: white;
  margin: 0;
  font-size: 24px;
  text-align: center;
}

.user-mini {
  color: white;
  font-size: 14px;
}

.main-content {
  padding: 30px;
  max-width: 800px;
  margin: 0 auto;
}

.tabs {
  display: flex;
  gap: 15px;
  margin-bottom: 25px;
}

.tabs button {
  flex: 1;
  padding: 14px;
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
}

.comments-section,
.photos-section {
  background: white;
  border-radius: 16px;
  padding: 25px;
}

.comment-form,
.upload-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 25px;
  padding-bottom: 25px;
  border-bottom: 1px solid #eee;
}

.comment-form textarea,
.upload-form input {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
  resize: none;
  box-sizing: border-box;
}

.upload-form input {
  resize: vertical;
}

.comment-form textarea:focus,
.upload-form input:focus {
  outline: none;
  border-color: #667eea;
}

.submit-btn {
  align-self: flex-end;
  padding: 10px 24px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
}

.submit-btn:disabled {
  background: #ccc;
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

.comments-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.comment-card {
  padding: 15px;
  background: #f9f9f9;
  border-radius: 12px;
}

.comment-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.comment-avatar {
  width: 40px;
  height: 40px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: bold;
}

.comment-meta {
  display: flex;
  flex-direction: column;
}

.comment-author {
  color: #333;
  font-weight: 500;
}

.comment-time {
  color: #999;
  font-size: 12px;
}

.comment-content {
  color: #555;
  line-height: 1.6;
}

.photo-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
}

.photo-item {
  text-align: center;
}

.photo-item img {
  width: 100%;
  height: 180px;
  object-fit: cover;
  border-radius: 12px;
}

.photo-item p {
  margin: 10px 0 5px;
  color: #333;
  font-weight: 500;
}

.photo-time {
  color: #999;
  font-size: 12px;
}
</style>