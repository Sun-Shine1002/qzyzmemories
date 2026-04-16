<template>
  <div class="profile-panel">
    <div class="panel-header">
      <h3>个人信息</h3>
      <button class="close-btn" @click="$emit('close')">×</button>
    </div>

    <div class="panel-content">
      <div class="avatar-section">
        <div class="avatar">{{ form.username?.charAt(0) || '?' }}</div>
      </div>

      <div class="form-section">
        <div class="form-group">
          <label>用户名</label>
          <input v-model="form.username" type="text" placeholder="请输入用户名" />
        </div>

        <div class="form-group">
          <label>班级</label>
          <input v-model="form.class_name" type="text" placeholder="如：高三(1)班" />
        </div>

        <div class="form-group">
          <label>毕业年份</label>
          <select v-model="form.graduation_year">
            <option value="2025">2025届</option>
            <option value="2026">2026届</option>
          </select>
          <p class="hint">选择后将影响可评论的回忆录范围</p>
        </div>

        <div class="form-group">
          <label>头像URL</label>
          <input v-model="form.avatar_url" type="text" placeholder="输入头像图片地址" />
        </div>

        <div class="cooldown-info" v-if="cooldownEndTime">
          <p v-if="isInCooldown" class="cooldown-warning">
            距离下次可更改毕业年份还有 <strong>{{ cooldownRemaining }}</strong>
          </p>
        </div>
      </div>

      <div class="btn-group">
        <button @click="handleSave" :disabled="saving || isInCooldown" class="save-btn">
          {{ saving ? '保存中...' : (isInCooldown ? '冷却中' : '保存') }}
        </button>
        <button @click="handleCancel" class="cancel-btn">取消</button>
      </div>

      <div v-if="successMsg" class="success-msg">{{ successMsg }}</div>
      <div v-if="errorMsg" class="error-msg">{{ errorMsg }}</div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '../lib/supabase'

const props = defineProps({
  user: Object,
  profile: Object
})

const emit = defineEmits(['close', 'update'])

const saving = ref(false)
const successMsg = ref('')
const errorMsg = ref('')
const cooldownEndTime = ref(null)
const cooldownRemaining = ref('')
let cooldownTimer = null

const THREE_MONTHS_MS = 90 * 24 * 60 * 60 * 1000 // 约3个月

const form = ref({
  username: '',
  class_name: '',
  graduation_year: '2025',
  avatar_url: ''
})

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
    localStorage.removeItem('yearChangeCooldown')
    return
  }

  const days = Math.floor(diff / (24 * 60 * 60 * 1000))
  const hours = Math.floor((diff % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000))
  cooldownRemaining.value = `${days}天${hours}小时`
}

const handleSave = async () => {
  if (!form.value.username) {
    errorMsg.value = '用户名不能为空'
    return
  }

  // 检查冷却时间
  if (isInCooldown.value) {
    errorMsg.value = `毕业年份更改冷却中，请${cooldownRemaining.value}后再试`
    return
  }

  // 检查是否更改了毕业年份
  const oldYear = props.profile?.graduation_year || '2025'
  const yearChanged = oldYear !== form.value.graduation_year

  saving.value = true
  errorMsg.value = ''
  successMsg.value = ''

  try {
    const data = {
      user_id: props.user.id,
      username: form.value.username,
      class_name: form.value.class_name,
      graduation_year: form.value.graduation_year,
      avatar_url: form.value.avatar_url,
      updated_at: new Date().toISOString()
    }

    if (yearChanged) {
      // 设置冷却时间
      cooldownEndTime.value = new Date(Date.now() + THREE_MONTHS_MS).toISOString()
      localStorage.setItem('yearChangeCooldown', cooldownEndTime.value)
      startCooldownTimer()
      data.year_changed_at = new Date().toISOString()
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

    successMsg.value = yearChanged ? '保存成功！毕业年份更改已锁定3个月' : '保存成功！'
    emit('update', data)
    setTimeout(() => { emit('close') }, 1500)
  } catch (err) {
    errorMsg.value = err.message || '保存失败'
  } finally {
    saving.value = false
  }
}

const startCooldownTimer = () => {
  cooldownTimer = setInterval(updateCooldownRemaining, 60000) // 每分钟更新
}

const handleCancel = () => {
  emit('close')
}

onMounted(() => {
  if (props.profile) {
    form.value = {
      username: props.profile.username || '',
      class_name: props.profile.class_name || '',
      graduation_year: props.profile.graduation_year || '2025',
      avatar_url: props.profile.avatar_url || ''
    }
  }

  // 检查冷却时间
  const savedCooldown = localStorage.getItem('yearChangeCooldown')
  if (savedCooldown) {
    cooldownEndTime.value = savedCooldown
    if (isInCooldown.value) {
      startCooldownTimer()
    }
  }
})

onUnmounted(() => {
  if (cooldownTimer) {
    clearInterval(cooldownTimer)
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
  width: 90px;
  height: 90px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 36px;
  font-weight: bold;
  margin: 0 auto;
}

.form-section {
  display: flex;
  flex-direction: column;
  gap: 20px;
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

.cooldown-info {
  padding: 12px;
  background: #fff3e0;
  border-radius: 8px;
}

.cooldown-warning {
  margin: 0;
  color: #e65100;
  font-size: 13px;
}

.cooldown-warning strong {
  color: #ff6d00;
}

.btn-group {
  display: flex;
  gap: 12px;
  margin-top: 25px;
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