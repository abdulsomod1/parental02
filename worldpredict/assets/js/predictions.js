// Predictions CRUD

// Create prediction
async function createPrediction(topic, predictionText) {
  const { error } = await supabase
    .from('predictions')
    .insert({ 
      user_id: currentUser.id,
      topic,
      prediction: predictionText 
    });
    
  if (error) throw error;
  
  // Log activity
  await logActivity(currentUser.id, 'prediction_created', { topic });
}

// Get user predictions
async function getUserPredictions(userId) {
  const { data, error } = await supabase
    .from('predictions')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });
    
  if (error) throw error;
  return data;
}

// Load user predictions UI
async function loadUserPredictions() {
  const predictions = await getUserPredictions(currentUser.id);
  const container = document.getElementById('predictionsList');
  container.innerHTML = predictions.map(p => `
    <div class="prediction-card card">
      <h4>${p.topic}</h4>
      <p>${p.prediction}</p>
      <small>${new Date(p.created_at).toLocaleString()}</small>
    </div>
  `).join('');
}

// Leaderboard (top predictors by count)
async function loadLeaderboard() {
  // RPC or agg query for top users by prediction count
  const { data, error } = await supabase
    .rpc('get_leaderboard');
    
  if (error) {
    console.error('Leaderboard error:', error);
    return;
  }
  
  const container = document.getElementById('leaderboardList');
  container.innerHTML = data.map((row, i) => `
    <div class="rank-item">
      <span>${i+1}. ${row.username}</span>
      <span>${row.prediction_count} predictions</span>
    </div>
  `).join('');
}

// Get child predictions (for parent)
async function getChildPredictions(childId) {
  return await getUserPredictions(childId);
}

// Get activity logs
async function getActivityLogs(userId, limit = 20) {
  const { data, error } = await supabase
    .from('activity_logs')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);
    
  if (error) throw error;
  return data;
}

// Load child data for parent
async function loadChildData() {
  const { data: links } = await supabase
    .from('parent_child_links')
    .select('child_id')
    .eq('parent_id', currentUser.id)
    .single();
    
  if (links) {
    const childProfile = await getUserProfile(links.child_id);
    document.getElementById('childInfo').innerHTML = `
      <p><strong>Child:</strong> ${childProfile.username} (${childProfile.child_code})</p>
    `;
  }
}

// Load child predictions
async function loadChildPredictions() {
  const { data: links } = await supabase.from('parent_child_links').select('child_id').eq('parent_id', currentUser.id).single();
  if (links) {
    const predictions = await getChildPredictions(links.child_id);
    document.getElementById('childPredictions').innerHTML = predictions.map(p => `
      <div class="prediction-card">
        <h5>${p.topic}</h5>
        <p>${p.prediction}</p>
      </div>
    `).join('');
  }
}

// Load activity logs UI
async function loadActivityLogs() {
  const { data: links } = await supabase.from('parent_child_links').select('child_id').eq('parent_id', currentUser.id).single();
  if (links) {
    const logs = await getActivityLogs(links.child_id);
    document.getElementById('activityLogs').innerHTML = logs.map(log => `
      <div class="rank-item">
        <span>${log.activity_type}</span>
        <span>${new Date(log.created_at).toLocaleString()}</span>
      </div>
    `).join('');
  }
}

function showMessage(msg, type) {
  // Global message handler - implement per page
  console.log(`${type.toUpperCase()}: ${msg}`);
}
