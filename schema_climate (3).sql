-- ============================================================
-- New Orleans Climate Aware Recommender
-- Database: PostgreSQL (Supabase)
-- ============================================================

-- 1. LOCATION
CREATE TABLE location (
    location_id  SERIAL       PRIMARY KEY,
    city         VARCHAR(100) NOT NULL,
    latitude     FLOAT        NOT NULL,
    longitude    FLOAT        NOT NULL,
    timezone     VARCHAR(50)  NOT NULL
);

-- Default: New Orleans
INSERT INTO location (city, latitude, longitude, timezone)
VALUES ('New Orleans', 29.9547, -90.0751, 'America/Chicago');

-- ============================================================

-- 2. WEATHER_CODE
CREATE TABLE weather_code (
    weather_code INT          PRIMARY KEY,
    description  VARCHAR(200) NOT NULL,
    category     VARCHAR(100) NOT NULL,
    icon_label   VARCHAR(50)
);

-- WMO standard codes
INSERT INTO weather_code (weather_code, description, category, icon_label) VALUES
(0,  'Clear sky',                          'Clear',       'clear'),
(1,  'Mainly clear',                       'Clear',       'mainly_clear'),
(2,  'Partly cloudy',                      'Cloudy',      'partly_cloudy'),
(3,  'Overcast',                           'Cloudy',      'overcast'),
(45, 'Fog',                                'Fog',         'fog'),
(48, 'Depositing rime fog',               'Fog',         'rime_fog'),
(51, 'Drizzle: light',                    'Drizzle',     'drizzle_light'),
(53, 'Drizzle: moderate',                 'Drizzle',     'drizzle_moderate'),
(55, 'Drizzle: dense',                    'Drizzle',     'drizzle_dense'),
(61, 'Rain: slight',                      'Rain',        'rain_slight'),
(63, 'Rain: moderate',                    'Rain',        'rain_moderate'),
(65, 'Rain: heavy',                       'Rain',        'rain_heavy'),
(71, 'Snowfall: slight',                  'Snow',        'snow_slight'),
(73, 'Snowfall: moderate',                'Snow',        'snow_moderate'),
(75, 'Snowfall: heavy',                   'Snow',        'snow_heavy'),
(80, 'Rain showers: slight',              'Showers',     'showers_slight'),
(81, 'Rain showers: moderate',            'Showers',     'showers_moderate'),
(82, 'Rain showers: violent',             'Showers',     'showers_violent'),
(95, 'Thunderstorm: slight or moderate',  'Thunderstorm','thunderstorm'),
(99, 'Thunderstorm with heavy hail',      'Thunderstorm','thunderstorm_hail');

-- ============================================================

-- 3. CLIMATE_DATA
-- Stores daily climate records from Open-Meteo Climate API
-- API endpoint: https://open-meteo.com/en/docs/climate-api
-- Location: New Orleans, LA (29.9547N, 90.0751W)
CREATE TABLE climate_data (
    climate_id             SERIAL    PRIMARY KEY,
    location_id            INT       NOT NULL REFERENCES location(location_id),
    record_date            DATE      NOT NULL,

    -- Temperature (°C)
    temp_max               FLOAT,
    temp_min               FLOAT,
    temp_mean              FLOAT,

    -- Precipitation (mm)
    precipitation_sum      FLOAT,
    rain_sum               FLOAT,
    snowfall_sum           FLOAT,

    -- Humidity (%)
    humidity_max           FLOAT,
    humidity_min           FLOAT,
    humidity_mean          FLOAT,

    -- Wind speed (km/h)
    wind_speed_mean        FLOAT,
    wind_speed_max         FLOAT,

    -- Cloud & radiation
    cloud_cover_mean       FLOAT,
    shortwave_radiation_sum FLOAT,

    -- Pressure & soil
    pressure_msl_mean      FLOAT,
    soil_moisture_mean     FLOAT,

    -- Weather condition
    weather_code           INT       REFERENCES weather_code(weather_code),

    fetched_at             TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE (location_id, record_date)
);

-- ============================================================

-- 4. USER_PREFERENCE
CREATE TABLE user_preference (
    preference_id      SERIAL       PRIMARY KEY,
    session_id         VARCHAR(100) NOT NULL,
    preferred_category VARCHAR(100),
    climate_tolerance  INT,
    prefer_indoor      BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ============================================================

-- 5. ACTIVITY
-- Activity categories from proposal:
--   Outdoor Sports, Indoor Activities,
--   Weather-Dependent Events, Seasonal Activities
CREATE TABLE activity (
    activity_id           SERIAL       PRIMARY KEY,
    name                  VARCHAR(100) NOT NULL,
    category              VARCHAR(100) NOT NULL,
    description           TEXT,

    -- Temperature thresholds (°C)
    min_temp              FLOAT,
    max_temp              FLOAT,

    -- Precipitation threshold (mm)
    max_precipitation_sum FLOAT,

    -- Wind speed threshold (km/h)
    max_wind_speed        FLOAT,

    -- Humidity threshold (%)
    max_humidity          FLOAT,

    -- Cloud cover threshold (%)
    max_cloud_cover       FLOAT,

    is_indoor             BOOLEAN      NOT NULL DEFAULT FALSE
);

-- Sample activities for New Orleans (from proposal)
INSERT INTO activity (name, category, description, min_temp, max_temp, max_precipitation_sum, max_wind_speed, max_humidity, max_cloud_cover, is_indoor) VALUES
-- Outdoor Sports
('Hiking',            'Outdoor Sports',             'Trail hiking around Audubon Park',               10, 30, 5,    30, 80, 70,  FALSE),
('Biking',            'Outdoor Sports',             'Cycling along the Mississippi levee',             10, 32, 2,    25, 80, 70,  FALSE),
('Kayaking',          'Outdoor Sports',             'Kayaking and boating along the Mississippi',      15, 35, 0,    20, 85, 60,  FALSE),

-- Indoor Activities
('Museum Visit',      'Indoor Activities',          'Visit NOMA or the WWII Museum',                  NULL, NULL, NULL, NULL, NULL, NULL, TRUE),
('Shopping',          'Indoor Activities',          'Shopping in the French Quarter',                 NULL, NULL, NULL, NULL, NULL, NULL, TRUE),
('Jazz Venue',        'Indoor Activities',          'Live jazz at Preservation Hall',                 NULL, NULL, NULL, NULL, NULL, NULL, TRUE),
('Indoor Dining',     'Indoor Activities',          'Dining at a local New Orleans restaurant',       NULL, NULL, NULL, NULL, NULL, NULL, TRUE),

-- Weather-Dependent Events
('Street Parade',     'Weather-Dependent Events',  'Second Line parades and street festivals',        15, 32, 2,    20, 80, 50,  FALSE),
('Crawfish Boil',     'Weather-Dependent Events',  'Outdoor crawfish boil event',                     18, 34, 5,    25, 80, 60,  FALSE),
('Outdoor Festival',  'Weather-Dependent Events',  'Jazz Fest and outdoor music festivals',           12, 32, 2,    20, 80, 60,  FALSE),
('Open-air Concert',  'Weather-Dependent Events',  'Outdoor concert at Lakefront Arena',              15, 32, 2,    20, 80, 60,  FALSE),

-- Seasonal Activities
('Fall Cultural Tour', 'Seasonal Activities',       'Fall cultural events and haunted history tours',  10, 25, 5,    30, 80, 80,  FALSE),
('Holiday Markets',   'Seasonal Activities',        'Holiday season markets and events',               5,  22, 5,    30, 85, 80,  FALSE);

-- ============================================================

-- 6. RECOMMENDATION
CREATE TABLE recommendation (
    recommendation_id INT       PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    climate_id        INT       NOT NULL REFERENCES climate_data(climate_id),
    activity_id       INT       NOT NULL REFERENCES activity(activity_id),
    preference_id     INT       REFERENCES user_preference(preference_id),
    suitability_score FLOAT,
    reason_summary    VARCHAR(500),
    generated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX idx_climate_data_location  ON climate_data(location_id);
CREATE INDEX idx_climate_data_date      ON climate_data(record_date);
CREATE INDEX idx_climate_data_code      ON climate_data(weather_code);
CREATE INDEX idx_recommendation_climate ON recommendation(climate_id);
CREATE INDEX idx_recommendation_activity ON recommendation(activity_id);
CREATE INDEX idx_recommendation_pref    ON recommendation(preference_id);
CREATE INDEX idx_user_pref_session      ON user_preference(session_id);

-- ============================================================
-- Useful views
-- ============================================================

-- Daily climate summary with weather description
CREATE VIEW v_climate_summary AS
SELECT
    cd.climate_id,
    l.city,
    cd.record_date,
    cd.temp_min,
    cd.temp_max,
    cd.temp_mean,
    cd.precipitation_sum,
    cd.rain_sum,
    cd.humidity_mean,
    cd.wind_speed_max,
    cd.cloud_cover_mean,
    cd.shortwave_radiation_sum,
    wc.description  AS weather_description,
    wc.category     AS weather_category,
    wc.icon_label
FROM climate_data cd
JOIN location     l  ON cd.location_id  = l.location_id
JOIN weather_code wc ON cd.weather_code = wc.weather_code;

-- Top recommendations per date
CREATE VIEW v_top_recommendations AS
SELECT
    r.recommendation_id,
    cd.record_date,
    l.city,
    a.name              AS activity_name,
    a.category          AS activity_category,
    a.is_indoor,
    r.suitability_score,
    r.reason_summary,
    wc.description      AS weather_description
FROM recommendation r
JOIN climate_data  cd ON r.climate_id  = cd.climate_id
JOIN activity      a  ON r.activity_id = a.activity_id
JOIN location      l  ON cd.location_id = l.location_id
JOIN weather_code  wc ON cd.weather_code = wc.weather_code
ORDER BY cd.record_date, r.suitability_score DESC;
