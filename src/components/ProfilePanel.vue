<template>
  <div class="profile-panel" @click.stop>
    <div class="panel-header">
      <h3>个人信息</h3>
      <button class="close-btn" @click="$emit('close')">×</button>
    </div>

    <div class="panel-content">
      <div class="avatar-section">
        <div class="avatar">{{ form.username?.charAt(0) || '?' }}</div>
        <p class="user-email">{{ user?.email }}</p>
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
          <label>个人简介</label>
          <textarea v-model="form.bio" placeholder="介绍一下自己..." rows="3"></textarea>
        </div>

        <div class="form-group">
          <label>头像URL</label>
          <input v-model="form.avatar_url" type="text" placeholder="输入头像图片地址" />
        </div>
      </div>

      <div class="btn-group">
        <button @click="handleSave" :disabled="saving" class="save-btn">
          {{ saving ? '保存中...' : '保存' }}
        </button>
        <button @click="handleCancel" class="cancel-btn">取消</button>
      </div>

      <div v-if="successMsg" class="success-msg">{{ successMsg }}</div>
      <div v-if="errorMsg" class="error-msg">{{ errorMsg }}</div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

const props = defineProps({
  user: Object,
  profile: Object
})

const emit = defineEmits(['close', 'update'])

const saving = ref(false)
const successMsg = ref('')
const errorMsg = ref('')

const form = ref({
  username: '',
  class_name: '',
  bio: '',
  avatar_url: ''
})

onMounted(() => {
  if (props.profile) {
    form.value = {
      username: props.profile.username || '',
      class_name: props.profile.class_name || '',
      bio: props.profile.bio || '',
      avatar_url: props.profile.avatar_url || ''
    }
  }
})

const handleSave = async () => {
  if (!form.value.username) {
    errorMsg.value = '用户名不能为空'
    return
  }

  saving.value = true
  errorMsg.value = ''
  successMsg.value = ''

  try {
    const data = {
      user_id: props.user.id,
      username: form.value.username,
      class_name: form.value.class_name,
      bio: form.value.bio,
      avatar_url: form.value.avatar_url,
      updated_at: new Date().toISOString()
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

    successMsg.value = '保存成功！'
    emit('update', data)
    setTimeout(() => { emit('close') }, 1000)
  } catch (err) {
    errorMsg.value = err.message || '保存失败'
  } finally {
    saving.value = false
  }
}

const handleCancel = () => {
  emit('close')
}
</script>

<style scoped>
.profile-panel {
  position: fixed;
  right: 0;
  top: 0;
  width: 400px;
  height: 100vh;
  background: white;
  box-shadow: -4px 0 20px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  overflow-y: auto;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #eee;
}

.panel-header h3 {
  margin: 0;
  color: #333;
}

.close-btn {
  width: 32px;
  height: 32px;
  border: none;
  background: none;
  font-size: 24px;
  color: #999;
  cursor: pointer;
}

.close-btn:hover {
  color: #333;
}

.panel-content {
  padding: 20px;
}

.avatar-section {
  text-align: center;
  margin-bottom: 30px;
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
  margin: 0 auto 15px;
}

.user-email {
  color: #666;
  margin: 0;
}

.form-section {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  color: #555;
  font-size: 14px;
  font-weight: 500;
}

.form-group input,
.form-group textarea {
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  font-family: inherit;
}

.form-group textarea {
  resize: vertical;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
}

.btn-group {
  display: flex;
  gap: 10px;
  margin-top: 20px;
}

.save-btn {
  flex: 1;
  padding: 12px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
}

.save-btn:disabled {
  background: #ccc;
}

.cancel-btn {
  padding: 12px 20px;
  background: #f5f5f5;
  color: #666;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
}

.success-msg {
  margin-top: 15px;
  padding: 10px;
  background: #efe;
  color: #3a3;
  border-radius: 8px;
  text-align: center;
  font-size: 14px;
}

.error-msg {
  margin-top: 15px;
  padding: 10px;
  background: #fee;
  color: #c33;
  border-radius: 8px;
  text-align: center;
  font-size: 14px;
}
</style>