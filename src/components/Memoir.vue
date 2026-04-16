<template>
  <div class="memoir-page">
    <header class="header">
      <button class="back-btn" @click="router.push('/dashboard')">← 返回</button>
      <h1>{{ year }}回忆录</h1>
      <div class="user-mini">
        <div class="user-avatar">{{ displayName }}</div>
        <span class="user-name">{{ username?.charAt(0) || '?' }}**</span>
      </div>
    </header>

    <main class="main-content">
      <!-- 章节选择 -->
      <div class="chapters-nav">
        <button
          v-for="chapter in chapters"
          :key="chapter.id"
          :class="{ active: activeChapter === chapter.id }"
          @click="selectChapter(chapter.id)"
        >
          {{ chapter.title }}
        </button>
      </div>

      <!-- 发帖区域 -->
      <div class="post-form">
        <div class="post-user">
          <div class="post-avatar">{{ displayName }}</div>
        </div>
        <div class="post-input-area">
          <textarea
            v-model="newPost.content"
            :placeholder="chapters[activeChapter - 1]?.placeholder"
            rows="4"
          ></textarea>
          <input
            v-model="newPost.imageUrl"
            type="text"
            placeholder="图片地址（可选）"
            class="image-input"
          />
          <div class="post-actions">
            <button @click="submitPost" :disabled="submitting" class="submit-btn">
              {{ submitting ? '发布中...' : '发布' }}
            </button>
          </div>
        </div>
      </div>

      <!-- 帖子列表 -->
      <div v-if="loadingPosts" class="loading">加载中...</div>
      <div v-else-if="postsError" class="error-msg">{{ postsError }}</div>
      <div v-else-if="posts.length === 0" class="empty-msg">
        <p>暂无回忆</p>
        <p class="sub-text">成为第一个分享的人吧！</p>
      </div>
      <div v-else class="posts-list">
        <div v-for="post in posts" :key="post.id" class="post-card">
          <div class="post-header">
            <div class="post-avatar">{{ post.displayName }}</div>
            <div class="post-meta">
              <span class="post-author">{{ post.displayName }}</span>
              <span class="post-time">{{ formatTime(post.created_at) }}</span>
            </div>
          </div>
          <div v-if="post.content" class="post-content">{{ post.content }}</div>
          <div v-if="post.image_url" class="post-image">
            <img :src="post.image_url" :alt="post.content || '图片'" />
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

const route = useRoute()
const router = useRouter()

const year = route.params.year || '2025'
const user = ref(null)
const username = ref('')
const activeChapter = ref(1)

const chapters = [
  { id: 1, title: '第一章', placeholder: '你们现在在哪个城市？' },
  { id: 2, title: '第二章', placeholder: '记忆中你印象最深刻的老师？' },
  { id: 3, title: '第三章', placeholder: '高中发生过什么印象深刻的事？' },
  { id: 4, title: '第四章', placeholder: '在一中的三年，你拍下的最喜欢的照片' },
  { id: 5, title: '第五章', placeholder: '高中时想说但未能说出的一句话？' },
  { id: 6, title: '第六章', placeholder: '如果能重回高中，你最想做什么？' },
  { id: 7, title: '第七章', placeholder: '大家的大学生活怎么样？' },
  { id: 8, title: '第八章', placeholder: '毕业后突然很想很想一中的时候？' },
  { id: 9, title: '第九章', placeholder: '你最想念一中什么饭菜呢？' },
  { id: 10, title: '第十章', placeholder: '一中生活中最让你忘不了的人？' },
  { id: 11, title: '第十一章', placeholder: '分享几张你大学生活的照片' },
  { id: 12, title: '第十二章', placeholder: '还有什么想说的？' }
]

const newPost = ref({
  content: '',
  imageUrl: ''
})

const submitting = ref(false)
const loadingPosts = ref(false)
const postsError = ref('')
const posts = ref([])

const displayName = computed(() => {
  if (!username.value) return '?'
  return username.value.charAt(0) + '**'
})

const selectChapter = async (chapterId) => {
  activeChapter.value = chapterId
  await loadPosts()
}

const loadPosts = async () => {
  loadingPosts.value = true
  postsError.value = ''

  try {
    const { data: postsData, error } = await supabase
      .from('posts')
      .select('*')
      .eq('graduation_year', year)
      .eq('chapter', activeChapter.value)
      .order('created_at', { ascending: false })

    if (error) throw error

    const userIds = [...new Set(postsData.map(p => p.user_id))]
    const { data: profilesData } = await supabase
      .from('user_profiles')
      .select('user_id, username')
      .in('user_id', userIds)

    const profileMap = {}
    profilesData?.forEach(p => { profileMap[p.user_id] = p.username })

    posts.value = postsData.map(p => ({
      ...p,
      displayName: profileMap[p.user_id]
        ? profileMap[p.user_id].charAt(0) + '**'
        : '匿名'
    }))
  } catch (err) {
    postsError.value = err.message || '加载失败'
  } finally {
    loadingPosts.value = false
  }
}

const submitPost = async () => {
  if (!newPost.value.content.trim() && !newPost.value.imageUrl.trim()) return

  submitting.value = true

  try {
    const { error } = await supabase
      .from('posts')
      .insert([
        {
          user_id: user.value.id,
          graduation_year: year,
          chapter: activeChapter.value,
          content: newPost.value.content.trim() || null,
          image_url: newPost.value.imageUrl.trim() || null
        }
      ])

    if (error) throw error

    newPost.value.content = ''
    newPost.value.imageUrl = ''
    await loadPosts()
  } catch (err) {
    alert(err.message || '发布失败')
  } finally {
    submitting.value = false
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
    username.value = userData.email?.split('@')[0] || ''

    const { data } = await supabase
      .from('user_profiles')
      .select('username')
      .eq('user_id', user.value.id)
      .single()

    if (data?.username) {
      username.value = data.username
    }

    await loadPosts()
  } else {
    router.push('/')
  }
})
</script>

<style scoped>
.memoir-page {
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

.back-btn {
  padding: 12px 24px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-size: 16px;
  transition: all 0.3s;
}

.back-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

.header h1 {
  color: white;
  margin: 0;
  font-size: 28px;
  letter-spacing: 4px;
}

.user-mini {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar,
.post-avatar {
  width: 45px;
  height: 45px;
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
  font-size: 16px;
}

.main-content {
  flex: 1;
  padding: 40px 80px;
  max-width: 1400px;
  margin: 0 auto;
  width: 100%;
  box-sizing: border-box;
}

.chapters-nav {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 30px;
  background: rgba(255, 255, 255, 0.95);
  padding: 20px;
  border-radius: 20px;
}

.chapters-nav button {
  padding: 14px 24px;
  background: #f0f0f0;
  color: #555;
  border: none;
  border-radius: 25px;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.3s;
}

.chapters-nav button.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.post-form {
  display: flex;
  gap: 20px;
  background: white;
  padding: 25px;
  border-radius: 20px;
  margin-bottom: 30px;
}

.post-user {
  flex-shrink: 0;
}

.post-input-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.post-input-area textarea,
.image-input {
  width: 100%;
  padding: 15px;
  border: 2px solid #eee;
  border-radius: 12px;
  font-size: 16px;
  font-family: inherit;
  resize: vertical;
  box-sizing: border-box;
  transition: border-color 0.3s;
}

.post-input-area textarea:focus,
.image-input:focus {
  outline: none;
  border-color: #667eea;
}

.post-actions {
  display: flex;
  justify-content: flex-end;
}

.submit-btn {
  padding: 14px 40px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  cursor: pointer;
  transition: opacity 0.3s;
}

.submit-btn:disabled {
  opacity: 0.6;
}

.loading, .error-msg, .empty-msg {
  text-align: center;
  padding: 60px;
  background: white;
  border-radius: 20px;
  color: #666;
  font-size: 18px;
}

.sub-text {
  font-size: 15px;
  color: #999;
  margin-top: 10px;
}

.posts-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.post-card {
  background: white;
  padding: 25px;
  border-radius: 20px;
}

.post-header {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 15px;
}

.post-meta {
  display: flex;
  flex-direction: column;
}

.post-author {
  color: #333;
  font-size: 16px;
  font-weight: 500;
}

.post-time {
  color: #999;
  font-size: 13px;
}

.post-content {
  color: #444;
  line-height: 1.8;
  margin-bottom: 15px;
  font-size: 16px;
}

.post-image img {
  width: 100%;
  max-height: 500px;
  object-fit: cover;
  border-radius: 12px;
}
</style>