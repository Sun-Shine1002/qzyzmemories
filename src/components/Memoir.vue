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
              <button
                v-if="post.user_id === user?.id"
                @click="handleDelete(post.id)"
                class="delete-btn"
              >
                删除
              </button>
            </div>
            <div v-if="post.content" class="post-content">{{ post.content }}</div>
            <div v-if="post.image_url" class="post-image" @click="previewImage(post.image_url)">
              <img :src="post.image_url" :alt="post.content || '图片'" />
              <div class="image-overlay">
                <span>点击查看/下载</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 展开的评论表单 -->
      <div v-if="showCommentForm" class="comment-form-expanded">
        <textarea
          v-model="newPost.content"
          :placeholder="chapters[activeChapter - 1]?.placeholder"
          rows="4"
        ></textarea>

        <!-- 图片上传 -->
        <div class="upload-section">
          <input
            ref="fileInput"
            type="file"
            accept="image/*"
            @change="handleFileSelect"
            style="display: none"
          />
          <button v-if="!uploadingImage && !newPost.imageUrl" @click="triggerFileInput" class="upload-btn">
            📷 上传照片
          </button>
          <div v-if="uploadingImage" class="uploading">
            <span class="spinner"></span>
            上传中...
          </div>
          <div v-if="newPost.imageUrl" class="image-preview">
            <img :src="newPost.imageUrl" alt="预览" />
            <button @click="removeImage" class="remove-btn">×</button>
          </div>
        </div>

        <div class="form-actions">
          <button @click="submitPost" :disabled="submitting || uploadingImage" class="submit-btn">
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
      @click="handleFabClick"
    >
      +
    </button>

    <!-- 图片预览弹窗 -->
    <div v-if="showPreview" class="preview-overlay" @click="showPreview = false">
      <div class="preview-content" @click.stop>
        <img :src="previewUrl" alt="预览" />
        <div class="preview-actions">
          <button @click.stop="downloadImage" class="download-btn">在新窗口打开</button>
          <button @click="showPreview = false" class="close-preview-btn">关闭</button>
        </div>
      </div>
    </div>
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
const userGraduationYear = ref(null)
const activeChapter = ref(1)
const showCommentForm = ref(false)
const fileInput = ref(null)
const uploadingImage = ref(false)

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
const previewUrl = ref('')
const showPreview = ref(false)

const previewImage = (url) => {
  previewUrl.value = url
  showPreview.value = true
}

const downloadImage = () => {
  window.open(previewUrl.value, '_blank')
}

const handleFabClick = () => {
  if (userGraduationYear.value && userGraduationYear.value !== year) {
    alert(`你选择了 ${userGraduationYear.value}届，只能在 ${userGraduationYear.value}回忆录中评论`)
    return
  }
  showCommentForm.value = true
}

const triggerFileInput = () => {
  fileInput.value?.click()
}

const handleFileSelect = async (event) => {
  const file = event.target.files?.[0]
  if (!file) return

  uploadingImage.value = true

  try {
    const fileExt = file.name.split('.').pop()
    const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`
    const filePath = `posts/${user.value.id}/${fileName}`

    const { error: uploadError } = await supabase.storage
      .from('photos')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false
      })

    if (uploadError) throw uploadError

    const { data } = supabase.storage.from('photos').getPublicUrl(filePath)
    console.log('图片URL:', data.publicUrl)
    newPost.value.imageUrl = data.publicUrl
  } catch (err) {
    alert('上传失败：' + (err.message || '请检查网络或重新尝试'))
  } finally {
    uploadingImage.value = false
  }
}

const removeImage = () => {
  newPost.value.imageUrl = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

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

const handleDelete = async (postId) => {
  if (!confirm('确定要删除这条回忆吗？')) return

  try {
    const { error } = await supabase
      .from('posts')
      .delete()
      .eq('id', postId)
      .eq('user_id', user.value.id)

    if (error) throw error

    await loadPosts()
  } catch (err) {
    alert('删除失败：' + (err.message || '请稍后重试'))
  }
}

const submitPost = async () => {
  if (userGraduationYear.value && userGraduationYear.value !== year) {
    alert(`你选择了 ${userGraduationYear.value}届，只能在 ${userGraduationYear.value}回忆录中评论`)
    return
  }

  if (!newPost.value.content.trim() && !newPost.value.imageUrl) {
    alert('请输入内容或上传图片')
    return
  }

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
          image_url: newPost.value.imageUrl || null
        }
      ])

    if (error) throw error

    newPost.value.content = ''
    newPost.value.imageUrl = ''
    if (fileInput.value) fileInput.value.value = ''
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
      .select('username, graduation_year')
      .eq('user_id', user.value.id)
      .single()

    if (data?.username) {
      username.value = data.username
    }
    if (data?.graduation_year) {
      userGraduationYear.value = data.graduation_year
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
  min-height: 100dvh;
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
  font-size: 18px;
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
  padding: 15px;
  max-width: 800px;
  margin: 0 auto;
  width: 100%;
  padding-bottom: 80px;
}

.chapters-nav {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 15px;
  background: rgba(255, 255, 255, 0.95);
  padding: 12px;
  border-radius: 16px;
}

.chapters-nav button {
  padding: 8px 14px;
  background: #f0f0f0;
  color: #555;
  border: none;
  border-radius: 20px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s;
}

.chapters-nav button.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.chapter-header {
  background: white;
  padding: 16px;
  border-radius: 16px;
  margin-bottom: 15px;
  text-align: center;
}

.chapter-header h2 {
  margin: 0;
  color: #333;
  font-size: 16px;
  font-weight: 500;
}

.posts-section {
  background: white;
  border-radius: 16px;
  padding: 16px;
  margin-bottom: 15px;
}

.loading, .error-msg, .empty-msg {
  text-align: center;
  padding: 40px 20px;
  color: #666;
  font-size: 14px;
}

.sub-text {
  font-size: 13px;
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
  margin-bottom: 10px;
  flex-wrap: wrap;
}

.post-author {
  color: #333;
  font-size: 14px;
  font-weight: 500;
}

.post-time {
  color: #999;
  font-size: 12px;
  flex: 1;
}

.delete-btn {
  padding: 4px 12px;
  background: #ff4444;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
}

.post-content {
  color: #444;
  line-height: 1.7;
  font-size: 14px;
  margin-bottom: 10px;
}

.post-image {
  position: relative;
  cursor: pointer;
  border-radius: 12px;
  overflow: hidden;
}

.post-image img {
  width: 100%;
  max-height: 400px;
  object-fit: cover;
  transition: opacity 0.3s;
}

.post-image:hover img {
  opacity: 0.8;
}

.image-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.3s;
}

.post-image:hover .image-overlay {
  opacity: 1;
}

.image-overlay span {
  color: white;
  font-size: 14px;
  background: rgba(0, 0, 0, 0.5);
  padding: 8px 16px;
  border-radius: 20px;
}

.comment-form-expanded {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  padding: 20px;
  box-shadow: 0 -4px 30px rgba(0, 0, 0, 0.2);
  border-radius: 20px 20px 0 0;
  max-width: 800px;
  margin: 0 auto;
  z-index: 200;
}

.comment-form-expanded textarea {
  width: 100%;
  padding: 14px;
  border: 2px solid #eee;
  border-radius: 12px;
  font-size: 14px;
  font-family: inherit;
  resize: vertical;
  margin-bottom: 12px;
}

.comment-form-expanded textarea:focus {
  outline: none;
  border-color: #667eea;
}

.upload-section {
  margin-bottom: 12px;
}

.upload-btn {
  padding: 10px 20px;
  background: #f5f5f5;
  color: #666;
  border: 2px dashed #ddd;
  border-radius: 10px;
  font-size: 14px;
  cursor: pointer;
  width: 100%;
}

.uploading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 15px;
  background: #f9f9f9;
  border-radius: 10px;
  color: #666;
  font-size: 14px;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid #ddd;
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.image-preview {
  position: relative;
  display: inline-block;
}

.image-preview img {
  max-width: 200px;
  max-height: 150px;
  border-radius: 10px;
  object-fit: cover;
}

.remove-btn {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 24px;
  height: 24px;
  background: #ff4444;
  color: white;
  border: none;
  border-radius: 50%;
  font-size: 14px;
  cursor: pointer;
  line-height: 24px;
}

.form-actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
}

.submit-btn {
  padding: 12px 28px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  cursor: pointer;
}

.submit-btn:disabled {
  opacity: 0.6;
}

.cancel-btn {
  padding: 12px 20px;
  background: #f5f5f5;
  color: #666;
  border: none;
  border-radius: 10px;
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
  box-shadow: 0 4px 20px rgba(102, 126, 234, 0.5);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
}

.preview-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.9);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.preview-content {
  max-width: 90%;
  max-height: 90%;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.preview-content img {
  max-width: 100%;
  max-height: calc(100vh - 120px);
  object-fit: contain;
  border-radius: 12px;
}

.preview-actions {
  display: flex;
  gap: 15px;
  justify-content: center;
}

.download-btn {
  padding: 12px 30px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 15px;
  cursor: pointer;
}

.close-preview-btn {
  padding: 12px 30px;
  background: #444;
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 15px;
  cursor: pointer;
}

/* 手机适配 */
@media (max-width: 600px) {
  .header {
    padding: 12px 15px;
  }

  .header h1 {
    font-size: 16px;
  }

  .main-content {
    padding: 12px;
    padding-bottom: 80px;
  }

  .chapters-nav {
    padding: 10px;
    gap: 6px;
  }

  .chapters-nav button {
    padding: 7px 11px;
    font-size: 11px;
  }

  .chapter-header {
    padding: 12px;
  }

  .chapter-header h2 {
    font-size: 14px;
  }

  .posts-section {
    padding: 12px;
  }

  .post-content {
    font-size: 13px;
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