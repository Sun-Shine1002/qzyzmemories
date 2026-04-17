-- 创建用户资料表
CREATE TABLE user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  class_name TEXT,
  graduation_year TEXT DEFAULT '2025',
  avatar_url TEXT,
  year_changed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- 启用 RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 策略：所有用户可查看
CREATE POLICY "Anyone can view user_profiles" ON user_profiles
  FOR SELECT USING (true);

-- 策略：用户可插入自己的资料
CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 策略：用户可更新自己的资料
CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- 策略：用户可删除自己的资料
CREATE POLICY "Users can delete own profile" ON user_profiles
  FOR DELETE USING (auth.uid() = user_id);

-- 创建帖子表（合并评论和图片）
CREATE TABLE posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  graduation_year TEXT NOT NULL,
  chapter INTEGER NOT NULL CHECK (chapter >= 1 AND chapter <= 12),
  content TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX idx_posts_graduation_year ON posts(graduation_year);
CREATE INDEX idx_posts_chapter ON posts(chapter);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- 启用 RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- 策略：所有用户可查看
CREATE POLICY "Anyone can view posts" ON posts
  FOR SELECT USING (true);

-- 策略：登录用户可发表
CREATE POLICY "Authenticated can insert posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 策略：用户可删除自己的帖子
CREATE POLICY "Users can delete own posts" ON posts
  FOR DELETE USING (auth.uid() = user_id);
