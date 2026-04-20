<template>
  <div class="profile-panel">
    <div class="panel-header">
      <h3>个人信息</h3>
      <button class="close-btn" @click="$emit('close')">×</button>
    </div>

    <div class="panel-content">
      <div class="avatar-section">
        <div class="avatar" @click="triggerAvatarUpload">
          <img v-if="form.avatar_url" :src="form.avatar_url" alt="头像" />
          <span v-else>{{ form.username?.charAt(0) || '?' }}</span>
        </div>
        <input
          ref="avatarInput"
          type="file"
          accept="image/*"
          @change="handleAvatarUpload"
          style="display: none"
        />
        <p class="avatar-hint">点击更换头像</p>
      </div>

      <div class="form-section">
        <div class="form-group">
          <label>用户名</label>
          <input v-model="form.username" type="text" placeholder="请输入用户名" />
        </div>

        <div class="form-group">
          <label>毕业年份</label>
          <select v-model="form.graduation_year">
            <option value="2025">2025届</option>
            <option value="2026">2026届</option>
          </select>
          <p class="hint" v-if="!isInCooldown">选择后将影响可评论的回忆录范围</p>
          <p class="cooldown-hint" v-else>
            更改毕业年份冷却中，还需 <strong>{{ cooldownRemaining }}</strong>
          </p>
        </div>

        <div class="btn-group">
          <button @click="handleSave" :disabled="saving" class="save-btn">
            {{ saving ? '保存中...' : '保存' }}
          </button>
          <button @click="handleCancel" class="cancel-btn">取消</button>
        </div>

        <div class="uploading-area" v-if="uploadingAvatar">
          <span class="spinner"></span>
          上传头像中...
        </div>

        <div class="success-msg" v-if="successMsg">{{ successMsg }}</div>
        <div class="error-msg" v-if="errorMsg">{{ errorMsg }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

const props = defineProps({
  user: Object,
  profile: Object
})

const emit = defineEmits(['close', 'update'])

const saving = ref(false)
const successMsg = ref('')
const errorMsg = ref('')
const uploadingAvatar = ref(false)
const avatarInput = ref(null)

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000

const form = ref({
  username: '',
  graduation_year: '2025',
  avatar_url: ''
})

const cooldownEndTime = ref(null)
const cooldownRemaining = ref('')
let cooldownTimer = null

const isInCooldown = computed(() => {
  if (!cooldownEndTime.value) return false
  return new Date(cooldownEndTime.value) > new Date()
})

const updateCooldownRemaining = () => {
  if (!cooldownEndTime.value) {
    cooldownRemaining.value = ''
    return
  }
  const end = new Date(cooldownEndTime.value)
  const now = new Date()
  const diff = end - now

  if (diff <= 0) {
    cooldownRemaining.value = ''
    cooldownEndTime.value = null
    localStorage.removeItem('yearChangeCooldown7d')
    if (cooldownTimer) clearInterval(cooldownTimer)
    return
  }

  const days = Math.floor(diff / (24 * 60 * 60 * 1000))
  const hours = Math.floor((diff % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000))
  cooldownRemaining.value = `${days}天${hours}小时`
}

const triggerAvatarUpload = () => {
  avatarInput.value?.click()
}

const handleAvatarUpload = async (event) => {
  const file = event.target.files?.[0]
  if (!file) return

  uploadingAvatar.value = true
  errorMsg.value = ''

  try {
    const fileExt = file.name.split('.').pop()
    const fileName = `avatar_${Date.now()}.${fileExt}`
    const filePath = `avatars/${props.user.id}/${fileName}`

    const { error: uploadError } = await supabase.storage
      .from('photos')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: true
      })

    if (uploadError) throw uploadError

    const { data } = supabase.storage.from('photos').getPublicUrl(filePath)
    form.value.avatar_url = data.publicUrl
  } catch (err) {
    errorMsg.value = '头像上传失败'
  } finally {
    uploadingAvatar.value = false
  }
}

const handleSave = async () => {
  if (!form.value.username) {
    errorMsg.value = '用户名不能为空'
    return
  }

  saving.value = true
  errorMsg.value = ''
  successMsg.value = ''

  try {
    const oldYear = props.profile?.graduation_year || '2025'
    const yearChanged = oldYear !== form.value.graduation_year

    // 如果年份改变且在冷却中，阻止保存（但允许保存其他信息）
    if (yearChanged && isInCooldown.value) {
      errorMsg.value = `毕业年份更改冷却中，还需 ${cooldownRemaining.value}，但其他信息仍可保存`
      // 这里我们仍然允许保存其他信息，只是年份不变
    }

    const data = {
      user_id: props.user.id,
      username: form.value.username,
      avatar_url: form.value.avatar_url,
      updated_at: new Date().toISOString()
    }

    // 只有年份改变且不在冷却时才更新年份
    if (yearChanged && !isInCooldown.value) {
      data.graduation_year = form.value.graduation_year
      data.year_changed_at = new Date().toISOString()
      cooldownEndTime.value = new Date(Date.now() + SEVEN_DAYS_MS).toISOString()
      localStorage.setItem('yearChangeCooldown7d', cooldownEndTime.value)
      startCooldownTimer()
    } else if (yearChanged && isInCooldown.value) {
      // 年份不变，只保留原值
      data.graduation_year = oldYear
    } else {
      data.graduation_year = form.value.graduation_year
    }

    if (props.profile?.id) {
      const { error } = await supabase
        .from('user_profiles')
        .update(data)
        .eq('user_id', props.user.id)

      if (error) throw error
    } else {
      const { error } = await supabase
        .from('user_profiles')
        .insert([data])

      if (error) throw error
    }

    const msg = yearChanged && !isInCooldown.value ? '保存成功！毕业年份更改已锁定3个月' : '保存成功！'
    successMsg.value = msg
    emit('update', data)
    setTimeout(() => { emit('close') }, 1500)
  } catch (err) {
    errorMsg.value = err.message || '保存失败'
  } finally {
    saving.value = false
  }
}

const startCooldownTimer = () => {
  if (cooldownTimer) clearInterval(cooldownTimer)
  cooldownTimer = setInterval(updateCooldownRemaining, 60000)
}

const handleCancel = () => {
  emit('close')
}

onMounted(() => {
  if (props.profile) {
    form.value = {
      username: props.profile.username || '',
      graduation_year: props.profile.graduation_year || '2025',
      avatar_url: props.profile.avatar_url || ''
    }
  }

  const savedCooldown = localStorage.getItem('yearChangeCooldown7d')
  if (savedCooldown) {
    cooldownEndTime.value = savedCooldown
    if (isInCooldown.value) {
      updateCooldownRemaining()
      startCooldownTimer()
    }
  }
})
</script>

<style scoped>
.profile-panel {
  position: fixed;
  right: 0;
  top: 0;
  width: 100%;
  max-width: 420px;
  height: 100vh;
  background: white;
  box-shadow: -4px 0 30px rgba(0, 0, 0, 0.15);
  z-index: 1000;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #eee;
  background: white;
  position: sticky;
  top: 0;
}

.panel-header h3 {
  margin: 0;
  color: #333;
  font-size: 18px;
}

.close-btn {
  width: 36px;
  height: 36px;
  border: none;
  background: #f5f5f5;
  font-size: 20px;
  color: #666;
  cursor: pointer;
  border-radius: 50%;
  transition: all 0.3s;
}

.close-btn:hover {
  background: #e0e0e0;
  color: #333;
}

.panel-content {
  padding: 25px;
  flex: 1;
}

.avatar-section {
  text-align: center;
  margin-bottom: 25px;
}

.avatar {
  width: 100px;
  height: 100px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 40px;
  font-weight: bold;
  margin: 0 auto;
  cursor: pointer;
  overflow: hidden;
  transition: all 0.3s;
}

.avatar:hover {
  transform: scale(1.05);
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-hint {
  margin: 10px 0 0;
  font-size: 13px;
  color: #999;
}

.uploading-area {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 12px;
  margin-top: 15px;
  background: #f5f5f5;
  border-radius: 8px;
  color: #666;
  font-size: 14px;
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid #ddd;
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.form-section {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-group label {
  color: #555;
  font-size: 14px;
  font-weight: 500;
}

.form-group input,
.form-group select {
  padding: 14px;
  border: 2px solid #eee;
  border-radius: 10px;
  font-size: 15px;
  transition: border-color 0.3s;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #667eea;
}

.hint {
  margin: 4px 0 0;
  font-size: 12px;
  color: #999;
}

.cooldown-hint {
  margin: 4px 0 0;
  font-size: 12px;
  color: #e65100;
}

.cooldown-hint strong {
  color: #ff6d00;
}

.btn-group {
  display: flex;
  gap: 12px;
  margin-top: 20px;
}

.save-btn {
  flex: 1;
  padding: 15px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-size: 15px;
  font-weight: 500;
  cursor: pointer;
}

.save-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.cancel-btn {
  padding: 15px 24px;
  background: #f5f5f5;
  color: #666;
  border: none;
  border-radius: 10px;
  font-size: 15px;
  cursor: pointer;
}

.success-msg {
  margin-top: 15px;
  padding: 14px;
  background: #efe;
  color: #2e7d32;
  border-radius: 10px;
  text-align: center;
  font-size: 14px;
}

.error-msg {
  margin-top: 15px;
  padding: 14px;
  background: #fee;
  color: #c62828;
  border-radius: 10px;
  text-align: center;
  font-size: 14px;
}
</style>