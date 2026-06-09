# New Orleans Climate-Aware Activity Recommender

**Developer:** Hongbo Zhang  
**Course:** MSBA-692-60-4265 · Pipelines to Insights — Summer 2026  
**Assignment:** Week 4 — Functional Dash Application (MVP)

---

## Business Problem

New Orleans attracts millions of visitors each year, yet many fail to account for the city's extreme subtropical climate — intense summer heat, high humidity, frequent thunderstorms, and seasonal hurricane risk from June through November. Poor weather planning leads to missed experiences and reduced tourist engagement with local businesses.

This application solves that problem by combining **real-time 16-day weather forecast data** with an **intelligent activity recommendation engine**, helping both visitors and locals plan their day around actual climate conditions across 14 New Orleans-specific activities.

---

## How to Run

### Step 1 — Install Dependencies

```bash
pip install dash dash-bootstrap-components plotly pandas requests sqlalchemy psycopg2-binary
```

### Step 2 — Open the Notebook

```bash
jupyter notebook NO_Climate_Recommender.ipynb
```

Run cells in order:

| Cell | Description |
|------|-------------|
| Step 1 | Install packages |
| Step 2a | Configure Supabase PostgreSQL connection |
| Step 2b | Run ETL pipeline (Extract → Transform → Load) |
| Step 3 | Launch the interactive Dash app |

### Step 3 — Access the App

After running Step 3, open your browser and go to:

```
http://127.0.0.1:8054
```

---

## Database Configuration (Supabase PostgreSQL)

1. Log in at [supabase.com](https://supabase.com)
2. Go to your project → **Settings** → **Database** → **Connection string (URI)**
3. Paste it into **Step 2a**:

```python
os.environ["POSTGRES_URI"] = "postgresql://postgres:YOUR_PASSWORD@db.YOUR_REF.supabase.co:5432/postgres"
```

> **Fallback:** If no database is configured, the app automatically uses the Open-Meteo Forecast API or a built-in static dataset. All dashboard features remain fully functional.

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `dash` ≥ 2.11 | Web application framework |
| `dash-bootstrap-components` | Responsive UI layout |
| `plotly` | Interactive charts and maps |
| `pandas` | Data transformation and aggregation |
| `requests` | Open-Meteo API calls |
| `sqlalchemy` | PostgreSQL ORM / query engine |
| `psycopg2-binary` | PostgreSQL driver |

---

## Database Schema

Hosted on **Supabase PostgreSQL**, using a star schema:

```
location        ← New Orleans coordinates (lat/lon/timezone)
weather_code    ← WMO code → human-readable description mapping
climate_data    ← Daily forecast records (upserted via ON CONFLICT)
activity        ← 14 New Orleans activity definitions + thresholds
user_preference ← Session-based user preferences
recommendation  ← Activity comfort scores per day
```

**ETL Strategy (Incremental Loading):**
- Extracts 16-day forecast from Open-Meteo API
- Transforms units: °F→°C, mph→km/h, inches→mm
- Upserts into `climate_data` using `ON CONFLICT (location_id, record_date) DO UPDATE`
- Scores all activities per day and writes to `recommendation` table
- Reads back via `v_climate_summary` view for dashboard display

---

## Dashboard Features

### Tab 1 — Activity Recommender
- **16-day date selector strip** — click any day to update all panels instantly
- **Weather conditions panel** — shows High/Low/Rain/Wind/Cloud for selected day
- **Activity recommendation list** — scored and ranked by comfort algorithm
- **Category filter dropdown** — filter by Outdoor Sports / Indoor / Events / Seasonal
- **Photo modal** — click any activity card to view 3 real photos, price range, Google rating, and comfort score with image carousel

### Tab 2 — Climate Data
- **6 KPI summary cards** — Avg High/Low Temp, Total Precip, Rainy Days, Avg Wind, Avg Cloud Cover
- **Temperature slider filter** — show only days where High Temp ≥ threshold (80–100°F)
- **Condition keyword search** — type "rain", "clear", or "storm" to filter rows
- **Scrollable data table** — full 16-day readings with frozen header, sortable columns, conditional formatting

### Tab 3 — Charts
- **Temperature range chart** — daily High/Mean/Low with shaded band
- **Precipitation & rain probability** — dual-axis bar + line chart
- **Heat Index (Feels Like °F)** — NOAA Rothfusz equation with color-coded danger zones (Comfortable / Caution / Danger / Extreme Danger)
- **New Orleans landmarks map** — embedded Google Maps showing famous attractions

### Tab 4 — Best Days
- **Top activity score chart** — horizontal bar ranked by day, highlights selected date in gold
- **Outdoor activity availability** — count of viable outdoor options per day
- **Click to navigate** — clicking a bar jumps to Recommender tab for that date and shows a weather + recommendation detail panel
- **Best day per activity table** — which day is optimal for each of 14 activities, sortable

---

## Recommendation Algorithm

Each activity is scored against daily weather using a **differentiated penalty model**:

```
score = base_score
      − temp_penalty     (distance from ideal temperature,   max 20 pts)
      − cloud_penalty    (distance from ideal cloud cover,   max 15 pts)
      − precip_penalty   (distance from ideal precipitation, max 20 pts)
      − wind_penalty     (distance from ideal wind speed,    max 10 pts)
      − prob_penalty     (rain probability × 0.20, outdoor only)
```

- **Indoor activities** have inverted ideals — they score *higher* when weather is bad
- Hard filters remove activities that violate safety thresholds (e.g. kayaking in rain)
- Scores clipped to [0, 100] and color-coded: 🟢 ≥75 · 🟡 ≥50 · 🔴 <50

---

## Business Insights

1. **June outdoor window is narrow** — only ~6 of 16 days have ≥5 viable outdoor options due to heat and storm risk
2. **Jazz clubs and museums dominate rainy periods** — indoor activities score 65–75 on high-cloud/high-rain days
3. **Crawfish Boils and Street Parades peak Mon–Tue Jun 8–9** — clear skies + moderate temps (84–88°F) = optimal outdoor conditions
4. **Heat Index exceeds 95°F on most days** — actual feels-like temperature is 10–15°F above thermometer readings; morning activity timing is critical
5. **Swamp Tours viable mid-June** — moderate temps + partial cloud create ideal wildlife viewing without excessive heat

---

## Project Structure

```
NO_Climate_Recommender.ipynb   ← Main notebook: ETL pipeline + Dash application
schema_climate.sql             ← PostgreSQL schema for Supabase
README.md                      ← This documentation
```

---

## 🔗 Data Sources

| Source | Usage |
|--------|-------|
| [Open-Meteo Forecast API](https://api.open-meteo.com) | 16-day weather forecast |
| [Supabase PostgreSQL](https://supabase.com) | Data persistence and querying |
| [Unsplash](https://unsplash.com) | Activity photos (direct links, no API key) |
| [Google Maps Embed](https://maps.google.com) | New Orleans landmarks map |

---

## 👤 Author

**Hongbo Zhang**  
MSBA-692-60-4265: Pipelines to Insights — Summer 2026  
Week 4 MVP Deliverable — Functional Dash Application
