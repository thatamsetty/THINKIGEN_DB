/**
 * Thinkigen ERP - Daily Timetable & Period Topic Management Frontend Logic
 * Supports Student / Parent "My Day" and Teacher "My Day & Workload" with inline topic updates.
 */

const API_BASE = "http://localhost:8000";

// Mock store state with row_version tokens and realistic topics
let state = {
  activeRole: "STUDENT", // 'STUDENT' or 'TEACHER'
  viewportMode: "DESKTOP", // 'DESKTOP' or 'MOBILE'
  activeTeacherId: 1,
  currentEditPeriodId: null,
  periods: [
    {
      timetable_period_id: 101,
      timetable_id: 1,
      period_date: "2026-09-16",
      period_number: 1,
      period_name: "Period 1",
      start_time: "08:30:00",
      end_time: "09:15:00",
      start_time_ist: "08:30:00",
      end_time_ist: "09:15:00",
      period_type: "CLASS",
      subject_id: 2,
      subject_name: "Mathematics",
      subject_code: "MAT",
      subject_topic: "Algebra Ex 3.1",
      teacher_id: 1,
      teacher_name: "Rajesh Sharma",
      class_name: "Class 10-A",
      room_name: "Room-01",
      activity_name: null,
      is_active: true,
      row_version: "0x0000000000000101"
    },
    {
      timetable_period_id: 102,
      timetable_id: 1,
      period_date: "2026-09-16",
      period_number: 2,
      period_name: "Period 2",
      start_time: "09:15:00",
      end_time: "10:00:00",
      start_time_ist: "09:15:00",
      end_time_ist: "10:00:00",
      period_type: "CLASS",
      subject_id: 3,
      subject_name: "Science",
      subject_code: "SCI",
      subject_topic: "Plant Cell Biology",
      teacher_id: 2,
      teacher_name: "Ananya Sen",
      class_name: "Class 10-A",
      room_name: "Room-01",
      activity_name: null,
      is_active: true,
      row_version: "0x0000000000000102"
    },
    {
      timetable_period_id: 103,
      timetable_id: 1,
      period_date: "2026-09-16",
      period_number: 3,
      period_name: "Morning Break",
      start_time: "10:00:00",
      end_time: "10:15:00",
      start_time_ist: "10:00:00",
      end_time_ist: "10:15:00",
      period_type: "BREAK",
      subject_id: null,
      subject_name: null,
      subject_code: null,
      subject_topic: null,
      teacher_id: null,
      teacher_name: null,
      class_name: null,
      room_name: null,
      activity_name: "Morning Refreshment Break",
      is_active: true,
      row_version: "0x0000000000000103"
    },
    {
      timetable_period_id: 104,
      timetable_id: 1,
      period_date: "2026-09-16",
      period_number: 4,
      period_name: "Period 3",
      start_time: "10:15:00",
      end_time: "11:00:00",
      start_time_ist: "10:15:00",
      end_time_ist: "11:00:00",
      period_type: "CLASS",
      subject_id: 1,
      subject_name: "English",
      subject_code: "ENG",
      subject_topic: "Poetry Analysis & Figures of Speech",
      teacher_id: 3,
      teacher_name: "Meera Nair",
      class_name: "Class 10-A",
      room_name: "Room-01",
      activity_name: null,
      is_active: true,
      row_version: "0x0000000000000104"
    },
    {
      timetable_period_id: 105,
      timetable_id: 1,
      period_date: "2026-09-16",
      period_number: 5,
      period_name: "Lunch Break",
      start_time: "11:45:00",
      end_time: "12:30:00",
      start_time_ist: "11:45:00",
      end_time_ist: "12:30:00",
      period_type: "LUNCH",
      subject_id: null,
      subject_name: null,
      subject_code: null,
      subject_topic: null,
      teacher_id: null,
      teacher_name: null,
      class_name: null,
      room_name: null,
      activity_name: "Lunch Break",
      is_active: true,
      row_version: "0x0000000000000105"
    },
    {
      timetable_period_id: 106,
      timetable_id: 2,
      period_date: "2026-09-16",
      period_number: 6,
      period_name: "Period 4 (Class 9-B)",
      start_time: "12:30:00",
      end_time: "13:15:00",
      start_time_ist: "12:30:00",
      end_time_ist: "13:15:00",
      period_type: "CLASS",
      subject_id: 2,
      subject_name: "Mathematics",
      subject_code: "MAT",
      subject_topic: "Quadratic Polynomials Ex 2.3",
      teacher_id: 1,
      teacher_name: "Rajesh Sharma",
      class_name: "Class 9-B",
      room_name: "Room-04",
      activity_name: null,
      is_active: true,
      row_version: "0x0000000000000106"
    }
  ]
};

// Preset topic suggestions for quick 1-click entry
const TOPIC_PRESETS = {
  "Mathematics": [
    "Algebra Ex 3.2 - Elimination Method",
    "Linear Equations Word Problems",
    "Quadratic Formula & Discriminant",
    "Chapter Review & Problem Solving"
  ],
  "Science": [
    "Plant Cell vs Animal Cell Structures",
    "Photosynthesis Light Reactions",
    "Newton's Second Law Numerical Problems",
    "Laboratory Practical Demonstration"
  ],
  "English": [
    "Formal Letter Writing Structure",
    "Active to Passive Voice Practice",
    "Shakespearean Sonnet 18 Discussion",
    "Vocabulary & Idioms Workshop"
  ]
};

// DOM Elements
const studentTabBtn = document.getElementById("tab-student");
const teacherTabBtn = document.getElementById("tab-teacher");
const desktopModeBtn = document.getElementById("btn-desktop-view");
const mobileModeBtn = document.getElementById("btn-mobile-view");
const viewportWrapper = document.getElementById("viewport-wrapper");
const profileBanner = document.getElementById("profile-banner");
const timelineList = document.getElementById("timeline-list");
const sectionHeading = document.getElementById("section-heading");
const editModal = document.getElementById("edit-modal");
const editTopicInput = document.getElementById("edit-topic-input");
const charCount = document.getElementById("char-count");
const presetsContainer = document.getElementById("presets-container");
const modalSubtitle = document.getElementById("modal-subtitle");
const btnSaveTopic = document.getElementById("btn-save-topic");
const btnCancelTopic = document.getElementById("btn-cancel-topic");
const btnCloseModal = document.getElementById("btn-close-modal");
const istTimeDisplay = document.getElementById("ist-time-display");

// Initialize application
document.addEventListener("DOMContentLoaded", () => {
  setupEventListeners();
  startClock();
  render();
});

function setupEventListeners() {
  studentTabBtn.addEventListener("click", () => setRole("STUDENT"));
  teacherTabBtn.addEventListener("click", () => setRole("TEACHER"));

  desktopModeBtn.addEventListener("click", () => setViewport("DESKTOP"));
  mobileModeBtn.addEventListener("click", () => setViewport("MOBILE"));

  editTopicInput.addEventListener("input", (e) => {
    charCount.textContent = `${e.target.value.length}/200`;
  });

  btnCancelTopic.addEventListener("click", closeModal);
  btnCloseModal.addEventListener("click", closeModal);
  btnSaveTopic.addEventListener("click", handleSaveTopic);

  editModal.addEventListener("click", (e) => {
    if (e.target === editModal) closeModal();
  });
}

function startClock() {
  function updateTime() {
    const now = new Date();
    // Format IST
    const options = { timeZone: "Asia/Kolkata", hour12: false, hour: "2-digit", minute: "2-digit", second: "2-digit" };
    const istString = now.toLocaleTimeString("en-GB", options);
    istTimeDisplay.textContent = `${istString} IST`;
  }
  updateTime();
  setInterval(updateTime, 1000);
}

function setRole(role) {
  state.activeRole = role;
  if (role === "STUDENT") {
    studentTabBtn.classList.add("active");
    teacherTabBtn.classList.remove("active");
  } else {
    teacherTabBtn.classList.add("active");
    studentTabBtn.classList.remove("active");
  }
  render();
}

function setViewport(mode) {
  state.viewportMode = mode;
  if (mode === "MOBILE") {
    mobileModeBtn.classList.add("active");
    desktopModeBtn.classList.remove("active");
    viewportWrapper.classList.add("mobile-frame");
  } else {
    desktopModeBtn.classList.add("active");
    mobileModeBtn.classList.remove("active");
    viewportWrapper.classList.remove("mobile-frame");
  }
}

function render() {
  renderProfile();
  renderTimeline();
}

function renderProfile() {
  if (state.activeRole === "STUDENT") {
    profileBanner.innerHTML = `
      <div class="profile-info">
        <div class="profile-avatar">AS</div>
        <div class="profile-titles">
          <h2>Aarav Sharma <span class="badge-success">Present Today</span></h2>
          <p>
            <span>Class 10-A</span> • 
            <span>Roll #14</span> • 
            <span class="badge-tag">CBSE Secondary</span>
          </p>
        </div>
      </div>
      <div class="stats-grid">
        <div class="stat-item">
          <div class="stat-value">5</div>
          <div class="stat-label">Total Periods</div>
        </div>
        <div class="stat-item">
          <div class="stat-value" style="color: #10b981;">3</div>
          <div class="stat-label">Academic Classes</div>
        </div>
        <div class="stat-item">
          <div class="stat-value" style="color: #f59e0b;">2</div>
          <div class="stat-label">Breaks</div>
        </div>
      </div>
    `;
    sectionHeading.innerHTML = `<span>📅</span> Today's Class Schedule & Daily Lesson Topics`;
  } else {
    profileBanner.innerHTML = `
      <div class="profile-info">
        <div class="profile-avatar" style="background: linear-gradient(135deg, #3b82f6, #06b6d4);">RS</div>
        <div class="profile-titles">
          <h2>Rajesh Sharma <span class="badge-tag">Department of Mathematics</span></h2>
          <p>
            <span>Senior Educator</span> • 
            <span>School ID #204</span> • 
            <span class="badge-success">On Duty</span>
          </p>
        </div>
      </div>
      <div class="stats-grid">
        <div class="stat-item">
          <div class="stat-value">2</div>
          <div class="stat-label">Classes Assigned</div>
        </div>
        <div class="stat-item">
          <div class="stat-value" style="color: #3b82f6;">Room-01 & 04</div>
          <div class="stat-label">Teaching Venues</div>
        </div>
        <div class="stat-item">
          <div class="stat-value" style="color: #10b981;">Active</div>
          <div class="stat-label">Status</div>
        </div>
      </div>
    `;
    sectionHeading.innerHTML = `<span>👩‍🏫</span> My Teaching Workload & Lesson Topic Manager`;
  }
}

function renderTimeline() {
  timelineList.innerHTML = "";

  const displayedPeriods = state.activeRole === "STUDENT"
    ? state.periods.filter(p => p.timetable_id === 1) // Student's section (10-A)
    : state.periods.filter(p => p.teacher_id === state.activeTeacherId); // Teacher's slots

  if (displayedPeriods.length === 0) {
    timelineList.innerHTML = `<div style="text-align: center; color: var(--text-dim); padding: 40px;">No periods scheduled for today.</div>`;
    return;
  }

  displayedPeriods.forEach((period) => {
    const card = document.createElement("div");
    card.className = `period-card type-${period.period_type.toLowerCase()}`;

    const isClass = period.period_type === "CLASS";

    // Column 1: Time & Period Number
    const timeCol = `
      <div class="period-time-col">
        <span class="period-num-badge">${period.period_name || `Slot #${period.period_number}`}</span>
        <span class="period-time-range">${period.start_time_ist.substring(0, 5)} - ${period.end_time_ist.substring(0, 5)}</span>
        <span class="period-duration">45 mins</span>
      </div>
    `;

    // Column 2: Subject & Topic details
    let topicHtml = "";
    if (isClass) {
      topicHtml = `
        <div class="topic-box" id="topic-box-${period.timetable_period_id}">
          <div class="topic-left">
            <span class="topic-icon">📖</span>
            <div class="topic-content-wrap">
              <span class="topic-header-label">Today's Lesson Topic (subject_topic)</span>
              <span class="topic-title-text" id="topic-text-${period.timetable_period_id}">
                ${escapeHtml(period.subject_topic || "No topic entered for today")}
              </span>
            </div>
          </div>
          ${state.activeRole === "TEACHER" ? `
            <button class="btn-outline" style="padding: 4px 10px; font-size: 0.76rem;" onclick="openEditModal(${period.timetable_period_id})">
              ✏️ Quick Edit
            </button>
          ` : ""}
        </div>
      `;
    }

    const detailsCol = `
      <div class="period-details-col">
        <div class="period-title-row">
          <span class="period-subject-name">${isClass ? period.subject_name : (period.activity_name || period.period_name)}</span>
          <span class="period-type-chip chip-${period.period_type.toLowerCase()}">${period.period_type}</span>
          ${period.class_name ? `<span class="badge-tag" style="background: rgba(255,255,255,0.06); color:#cbd5e1;">${period.class_name}</span>` : ""}
        </div>
        <div class="period-sub-meta">
          ${isClass ? `
            <span class="meta-item"><span>🏛️</span> ${period.room_name || "Assigned Room"}</span>
            <span class="meta-item"><span>👤</span> ${period.teacher_name || "Assigned Faculty"}</span>
          ` : `
            <span class="meta-item"><span>☕</span> School Common Area</span>
          `}
        </div>
        ${topicHtml}
      </div>
    `;

    // Column 3: Actions (for Teacher View)
    let actionsCol = "";
    if (state.activeRole === "TEACHER" && isClass) {
      actionsCol = `
        <div class="period-actions-col">
          <button class="btn-primary" onclick="openEditModal(${period.timetable_period_id})">
            <span>✏️</span> Edit Topic
          </button>
        </div>
      `;
    }

    card.innerHTML = timeCol + detailsCol + actionsCol;
    timelineList.appendChild(card);
  });
}

function openEditModal(periodId) {
  const period = state.periods.find(p => p.timetable_period_id === periodId);
  if (!period) return;

  state.currentEditPeriodId = periodId;
  modalSubtitle.textContent = `${period.subject_name} • ${period.class_name || "Section A"} • Slot ${period.period_number} (${period.start_time_ist.substring(0, 5)})`;
  
  editTopicInput.value = period.subject_topic || "";
  charCount.textContent = `${editTopicInput.value.length}/200`;

  // Render suggestion chips
  presetsContainer.innerHTML = "";
  const suggestions = TOPIC_PRESETS[period.subject_name] || [
    "Chapter Overview & Key Terms",
    "Ex 4.1 Problem Solutions",
    "Interactive Class Quiz",
    "Review & Homework Q&A"
  ];

  suggestions.forEach(text => {
    const chip = document.createElement("button");
    chip.type = "button";
    chip.className = "chip-suggestion";
    chip.textContent = text;
    chip.onclick = () => {
      editTopicInput.value = text;
      charCount.textContent = `${text.length}/200`;
    };
    presetsContainer.appendChild(chip);
  });

  editModal.classList.add("open");
  editTopicInput.focus();
}

function closeModal() {
  editModal.classList.remove("open");
  state.currentEditPeriodId = null;
}

async function handleSaveTopic() {
  const newTopic = editTopicInput.value.trim();
  const periodId = state.currentEditPeriodId;
  if (!periodId) return;

  const period = state.periods.find(p => p.timetable_period_id === periodId);
  if (!period) return;

  const originalTopic = period.subject_topic;
  const currentToken = period.row_version;

  // Optimistic UI update
  period.subject_topic = newTopic;
  renderTimeline();
  closeModal();

  try {
    // Attempt real PATCH call to FastAPI server
    const response = await fetch(`${API_BASE}/timetable/period/${periodId}/topic`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        subject_topic: newTopic,
        row_version: currentToken
      })
    });

    if (response.ok) {
      const data = await response.json();
      period.row_version = data.row_version;
      showToast(`✅ Topic updated successfully to "${newTopic}"`);
    } else if (response.status === 409) {
      // Concurrency conflict
      period.subject_topic = originalTopic;
      renderTimeline();
      showToast("⚠️ Concurrency Conflict: Another teacher modified this slot. Refreshing...", "error");
    } else {
      // Offline / dev fallback: advance local token
      const nextToken = "0x" + (parseInt(period.row_version, 16) + 1).toString(16).padStart(16, "0");
      period.row_version = nextToken;
      showToast(`✅ Topic updated for today: "${newTopic}"`);
    }
  } catch (err) {
    // Graceful offline fallback
    const nextToken = "0x" + (parseInt(period.row_version, 16) + 1).toString(16).padStart(16, "0");
    period.row_version = nextToken;
    showToast(`✅ Topic updated: "${newTopic}"`);
  }
}

function showToast(message, type = "success") {
  const container = document.getElementById("toast-container");
  const toast = document.createElement("div");
  toast.className = "toast";
  if (type === "error") {
    toast.style.borderLeftColor = "var(--accent-rose)";
  }
  toast.textContent = message;
  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transform = "translateY(10px)";
    toast.style.transition = "0.3s";
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

function escapeHtml(str) {
  if (!str) return "";
  return str.replace(/[&<>'"]/g, 
    tag => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[tag] || tag)
  );
}

// Attach to window for onclick handlers in dynamically generated HTML
window.openEditModal = openEditModal;
