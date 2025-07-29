-- Initialize PostgreSQL database for VidSage
-- This script runs automatically when the container starts

-- Enable the pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Create additional databases for test environment
CREATE DATABASE vidsage_test;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE vidsage_development TO postgres;
GRANT ALL PRIVILEGES ON DATABASE vidsage_test TO postgres;

-- Display confirmation
SELECT 'VidSage PostgreSQL database initialized with pgvector extension' AS status; 