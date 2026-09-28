-- Spotify Music Data Analysis
-- Portfolio SQL analysis of Spotify popularity, audio features, and music trends
-- SQL / MySQL portfolio project
--
-- Original project: MIS202 - Managing Data and Information
-- This version removes personal file paths and university submission details.

CREATE DATABASE IF NOT EXISTS spotify_business_analysis;
USE spotify_business_analysis;

-- ================================================================
-- TABLE SETUP
-- ================================================================

DROP TABLE IF EXISTS tracks;
DROP TABLE IF EXISTS features;
DROP TABLE IF EXISTS artists;
DROP TABLE IF EXISTS albums;

CREATE TABLE tracks (
    id VARCHAR(50),
    track_popularity INT,
    explicit BOOLEAN
);

CREATE TABLE features (
    danceability DOUBLE,
    energy DOUBLE,
    `key` INT,
    loudness DOUBLE,
    mode INT,
    speechiness DOUBLE,
    acousticness DOUBLE,
    instrumentalness DOUBLE,
    liveness DOUBLE,
    valence DOUBLE,
    tempo DOUBLE,
    `type` VARCHAR(50),
    id VARCHAR(50),
    uri VARCHAR(100),
    track_href VARCHAR(255),
    analysis_url VARCHAR(255),
    duration_ms INT,
    time_signature INT
);

CREATE TABLE artists (
    id VARCHAR(50),
    name VARCHAR(255),
    artist_popularity INT,
    artist_genres TEXT,
    followers INT,
    genre_0 VARCHAR(255),
    genre_1 VARCHAR(255),
    genre_2 VARCHAR(255),
    genre_3 VARCHAR(255),
    genre_4 VARCHAR(255),
    genre_5 VARCHAR(255),
    genre_6 VARCHAR(255)
);

CREATE TABLE albums (
    track_name VARCHAR(255),
    track_id VARCHAR(50),
    track_number INT,
    duration_ms INT,
    album_type VARCHAR(50),
    `artists` TEXT,
    total_tracks INT,
    album_name VARCHAR(255),
    release_date VARCHAR(50),
    label VARCHAR(255),
    album_popularity INT,
    album_id VARCHAR(50),
    artist_id VARCHAR(50),
    artist_0 VARCHAR(255),
    artist_1 VARCHAR(255),
    artist_2 VARCHAR(255),
    artist_3 VARCHAR(255),
    artist_4 VARCHAR(255),
    artist_5 VARCHAR(255),
    artist_6 VARCHAR(255),
    artist_7 VARCHAR(255),
    artist_8 VARCHAR(255),
    artist_9 VARCHAR(255),
    artist_10 VARCHAR(255),
    artist_11 VARCHAR(255),
    duration_sec DOUBLE
);

-- ================================================================
-- DATA IMPORT
-- ================================================================
-- Import the following CSV files into the matching tables using
-- MySQL Workbench's Table Data Import Wizard, or adapt LOAD DATA
-- LOCAL INFILE statements to your local file paths:
--
-- spotify_tracks_data_2023.csv   -> tracks
-- spotify_features_data_2023.csv -> features
-- spotify_artist_data_2023.csv   -> artists
-- spotify_albums_data_2023.csv   -> albums

-- ================================================================
-- QUERY 1: TOP ARTISTS BY FOLLOWERS
-- ================================================================

SELECT
    name AS artist_name,
    followers,
    genre_0 AS genre
FROM artists
ORDER BY followers DESC
LIMIT 10;

-- ================================================================
-- QUERY 2: MOST POPULAR TRACKS AND ALBUM ASSOCIATION
-- ================================================================
-- Some tracks appear through multiple album associations, so
-- ROW_NUMBER() is used to retain one album association per track.

WITH ranked_tracks AS (
    SELECT
        t.id,
        a.track_name,
        t.track_popularity,
        a.album_name,
        ROW_NUMBER() OVER (
            PARTITION BY t.id
            ORDER BY a.album_popularity DESC, a.album_name ASC
        ) AS rn
    FROM tracks t
    JOIN albums a
        ON t.id = a.track_id
)
SELECT
    track_name,
    track_popularity,
    album_name
FROM ranked_tracks
WHERE rn = 1
ORDER BY track_popularity DESC, track_name ASC
LIMIT 10;

-- ================================================================
-- QUERY 3: CLASSICAL GENRE ANALYSIS
-- ================================================================

SELECT
    genre_0 AS genre,
    COUNT(*) AS row_count
FROM artists
WHERE genre_0 LIKE '%classical%'
GROUP BY genre_0
ORDER BY genre_0 ASC;

SELECT
    COUNT(DISTINCT genre_0) AS total_different_classical_genres
FROM artists
WHERE genre_0 LIKE '%classical%';

-- ================================================================
-- QUERY 4A: FIVE MOST POPULAR ARTISTS
-- ================================================================

SELECT
    name AS artist_name,
    artist_popularity,
    genre_0 AS genre,
    followers
FROM artists
ORDER BY artist_popularity DESC, followers DESC
LIMIT 5;

-- ================================================================
-- QUERY 4B: FIVE LEAST POPULAR ARTISTS WITH >= 1,000 FOLLOWERS
-- ================================================================

SELECT
    name AS artist_name,
    artist_popularity,
    genre_0 AS genre,
    followers
FROM artists
WHERE followers >= 1000
ORDER BY artist_popularity ASC, followers ASC
LIMIT 5;

-- ================================================================
-- QUERY 5A: TOP ARTISTS BY AVERAGE SPEECHINESS
-- ================================================================

SELECT
    ar.name AS artist_name,
    ROUND(AVG(f.speechiness), 3) AS avg_speechiness
FROM (
    SELECT DISTINCT track_id, artist_id
    FROM albums
) a
JOIN features f
    ON a.track_id = f.id
JOIN artists ar
    ON a.artist_id = ar.id
GROUP BY ar.id, ar.name
ORDER BY avg_speechiness DESC
LIMIT 5;

-- ================================================================
-- QUERY 5B: TOP ARTISTS BY AVERAGE LIVENESS
-- ================================================================

SELECT
    ar.name AS artist_name,
    ROUND(AVG(f.liveness), 3) AS avg_liveness
FROM (
    SELECT DISTINCT track_id, artist_id
    FROM albums
) a
JOIN features f
    ON a.track_id = f.id
JOIN artists ar
    ON a.artist_id = ar.id
GROUP BY ar.id, ar.name
ORDER BY avg_liveness DESC
LIMIT 5;

-- ================================================================
-- QUERY 5C: TOP ARTISTS BY AVERAGE DANCEABILITY
-- ================================================================

SELECT
    ar.name AS artist_name,
    ROUND(AVG(f.danceability), 3) AS avg_danceability
FROM (
    SELECT DISTINCT track_id, artist_id
    FROM albums
) a
JOIN features f
    ON a.track_id = f.id
JOIN artists ar
    ON a.artist_id = ar.id
GROUP BY ar.id, ar.name
ORDER BY avg_danceability DESC
LIMIT 5;

-- ================================================================
-- QUERY 5D: TOP ARTISTS BY AVERAGE INSTRUMENTALNESS
-- ================================================================

SELECT
    ar.name AS artist_name,
    ROUND(AVG(f.instrumentalness), 3) AS avg_instrumentalness
FROM (
    SELECT DISTINCT track_id, artist_id
    FROM albums
) a
JOIN features f
    ON a.track_id = f.id
JOIN artists ar
    ON a.artist_id = ar.id
GROUP BY ar.id, ar.name
ORDER BY avg_instrumentalness DESC
LIMIT 5;

-- ================================================================
-- QUERY 6: DANCEABILITY TRENDS ACROSS DECADES
-- ================================================================
-- Filters:
--   * artist popularity >= 70
--   * track popularity >= 70
--   * non-explicit tracks only
-- The top qualifying track in each decade is selected by
-- danceability, with track and artist popularity as tie-breakers.

WITH base_data AS (
    SELECT DISTINCT
        a.track_id,
        a.artist_id,
        a.track_name,
        a.album_name,
        a.release_date,
        CAST(LEFT(a.release_date, 4) AS UNSIGNED) AS release_year,
        t.track_popularity,
        t.explicit,
        ar.name AS artist_name,
        ar.artist_popularity,
        ar.genre_0 AS genre,
        f.danceability,
        f.acousticness,
        f.energy,
        f.speechiness,
        f.liveness
    FROM albums a
    JOIN tracks t
        ON a.track_id = t.id
    JOIN features f
        ON a.track_id = f.id
    JOIN artists ar
        ON a.artist_id = ar.id
    WHERE ar.artist_popularity >= 70
      AND t.track_popularity >= 70
      AND t.explicit = 0
      AND a.release_date IS NOT NULL
      AND LEFT(a.release_date, 4) REGEXP '^[0-9]{4}$'
),
ranked_tracks AS (
    SELECT
        FLOOR(release_year / 10) * 10 AS decade,
        release_year,
        release_date,
        track_name,
        track_popularity,
        artist_name,
        artist_popularity,
        album_name,
        genre,
        danceability,
        acousticness,
        energy,
        speechiness,
        liveness,
        ROW_NUMBER() OVER (
            PARTITION BY FLOOR(release_year / 10) * 10
            ORDER BY danceability DESC, track_popularity DESC, artist_popularity DESC
        ) AS rn
    FROM base_data
)
SELECT
    release_year,
    release_date,
    track_name,
    track_popularity,
    artist_name,
    artist_popularity,
    album_name,
    genre,
    danceability,
    acousticness,
    energy,
    speechiness,
    liveness
FROM ranked_tracks
WHERE rn = 1
ORDER BY release_year ASC;
