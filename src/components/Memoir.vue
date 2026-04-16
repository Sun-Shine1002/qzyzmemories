<template>
  <div class="memoir-page">
    <header class="header">
      <button class="back-btn" @click="router.push('/dashboard')">← 返回</button>
      <h1>{{ year }}回忆录</h1>
      <div class="user-mini">
        <span class="user-name">{{ username?.charAt(0) || '?' }}**</span>
      </div>
    </header>

    <main class="main-content">
      <!-- 章节导航 -->
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

      <!-- 当前章节标题 -->
      <div class="chapter-header">
        <h2>{{ chapters[activeChapter - 1]?.placeholder }}</h2>
      </div>

      <!-- 评论列表 -->
      <div class="posts-section">
        <div v-if="loadingPosts" class="loading">加载中...</div>
        <div v-else-if="postsError" class="error-msg">{{ postsError }}</div>
        <div v-else-if="posts.length === 0" class="empty-msg">
          <p>暂无回忆</p>
          <p class="sub-text">成为第一个分享的人吧！</p>
        </div>
        <div v-else class="posts-list">
          <div v-for="post in posts" :key="post.id" class="post-card">
            <div class="post-meta">
              <span class="post-author">{{ post.displayName }}</span>
              <span class="post-time">{{ formatTime(post.created_at) }}</span>
            </div>
            <div v-if="post.content" class="post-content">{{ post.content }}</div>
            <div v-if="post.image_url" class="post-image">
              <img :src="post.image_url" :alt="post.content || '图片'" />
            </div>
          </div>
        </div>
      </div>

      <!-- 展开的评论表单 -->
      <div v-if="showCommentForm" class="comment-form-expanded">
        <textarea
          v-model="newPost.content"
          placeholder="写下你的回忆..."
          rows="4"
        ></textarea>
        <input
          v-model="newPost.imageUrl"
          type="text"
          placeholder="图片地址（可选）"
          class="image-input"
        />
        <div class="form-actions">
          <button @click="submitPost" :disabled="submitting" class="submit-btn">
            {{ submitting ? '发布中...' : '发布' }}
          </button>
          <button @click="showCommentForm = false" class="cancel-btn">收起</button>
        </div>
      </div>
    </main>

    <!-- 悬浮添加按钮 -->
    <button
      v-if="!showCommentForm"
      class="fab"
      @click="showCommentForm = true"
    >
      +
    </button>
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
const username = ref('')
const activeChapter = ref(1)
const showCommentForm = ref(false)

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

const selectChapter = async (chapterId) => {
  activeChapter.value = chapterId
  showCommentForm.value = false
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
    showCommentForm.value = false
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
* {
  box-sizing: border-box;
}

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
  padding: 15px 20px;
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(15px);
  position: sticky;
  top: 0;
  z-index: 100;
}

.back-btn {
  padding: 8px 16px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
}

.header h1 {
  color: white;
  margin: 0;
  font-size: 20px;
  letter-spacing: 2px;
}

.user-name {
  color: white;
  font-size: 14px;
  background: rgba(255, 255, 255, 0.2);
  padding: 6px 12px;
  border-radius: 15px;
}

.main-content {
  flex: 1;
  padding: 20px;
  max-width: 800px;
  margin: 0 auto;
  width: 100%;
  padding-bottom: 80px;
}

.chapters-nav {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 20px;
  background: rgba(255, 255, 255, 0.95);
  padding: 15px;
  border-radius: 16px;
}

.chapters-nav button {
  padding: 10px 16px;
  background: #f5f5f5;
  color: #555;
  border: none;
  border-radius: 20px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.3s;
}

.chapters-nav button.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.chapter-header {
  background: white;
  padding: 20px;
  border-radius: 16px;
  margin-bottom: 20px;
  text-align: center;
}

.chapter-header h2 {
  margin: 0;
  color: #333;
  font-size: 18px;
  font-weight: 500;
}

.posts-section {
  background: white;
  border-radius: 16px;
  padding: 20px;
  margin-bottom: 20px;
}

.loading, .error-msg, .empty-msg {
  text-align: center;
  padding: 40px 20px;
  color: #666;
}

.sub-text {
  font-size: 14px;
  color: #999;
  margin-top: 8px;
}

.posts-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.post-card {
  padding-bottom: 20px;
  border-bottom: 1px solid #eee;
}

.post-card:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.post-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}

.post-author {
  color: #333;
  font-size: 15px;
  font-weight: 500;
}

.post-time {
  color: #999;
  font-size: 12px;
}

.post-content {
  color: #444;
  line-height: 1.7;
  font-size: 15px;
  margin-bottom: 12px;
}

.post-image img {
  width: 100%;
  max-height: 400px;
  object-fit: cover;
  border-radius: 12px;
}

.comment-form-expanded {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  padding: 20px;
  box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.15);
  border-radius: 20px 20px 0 0;
  max-width: 800px;
  margin: 0 auto;
  z-index: 200;
}

.comment-form-expanded textarea,
.comment-form-expanded .image-input {
  width: 100%;
  padding: 12px;
  border: 2px solid #eee;
  border-radius: 12px;
  font-size: 15px;
  font-family: inherit;
  resize: vertical;
  margin-bottom: 12px;
}

.comment-form-expanded textarea:focus,
.comment-form-expanded .image-input:focus {
  outline: none;
  border-color: #667eea;
}

.form-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.submit-btn {
  padding: 10px 24px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
}

.submit-btn:disabled {
  opacity: 0.6;
}

.cancel-btn {
  padding: 10px 20px;
  background: #f5f5f5;
  color: #666;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
}

.fab {
  position: fixed;
  bottom: 20px;
  left: 20px;
  width: 56px;
  height: 56px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 50%;
  font-size: 32px;
  cursor: pointer;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 手机适配 */
@media (max-width: 600px) {
  .header {
    padding: 12px 15px;
  }

  .header h1 {
    font-size: 16px;
    letter-spacing: 1px;
  }

  .back-btn {
    padding: 6px 12px;
    font-size: 13px;
  }

  .main-content {
    padding: 15px;
    padding-bottom: 80px;
  }

  .chapters-nav {
    padding: 12px;
    gap: 6px;
  }

  .chapters-nav button {
    padding: 8px 12px;
    font-size: 12px;
  }

  .chapter-header {
    padding: 15px;
  }

  .chapter-header h2 {
    font-size: 15px;
  }

  .posts-section {
    padding: 15px;
  }

  .post-content {
    font-size: 14px;
  }

  .fab {
    bottom: 15px;
    left: 15px;
    width: 50px;
    height: 50px;
    font-size: 28px;
  }

  .comment-form-expanded {
    padding: 15px;
  }
}
</style>