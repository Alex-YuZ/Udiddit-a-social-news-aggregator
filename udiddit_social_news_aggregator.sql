DROP TABLE IF EXISTS "users" CASCADE;
DROP TABLE IF EXISTS "topics" CASCADE;
DROP TABLE IF EXISTS "posts" CASCADE;
DROP TABLE IF EXISTS "comments" CASCADE;
DROP TABLE IF EXISTS "votes" CASCADE;
 
-- Guidline #1: a. Create "users" table
CREATE TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "user_name" VARCHAR(25) NOT NULL,
  "login_in" TIMESTAMP WITH TIME ZONE,
  CONSTRAINT "unique_user_name" UNIQUE ("user_name"),
  CONSTRAINT "non_empty_user_name" CHECK(LENGTH(TRIM("user_name"))>0)
 );
CREATE INDEX "user_name_index" ON "users" ("user_name");

-- Guidline #1: b. Create "topics" table
CREATE TABLE "topics" (
  "id" SERIAL PRIMARY KEY,
  "topic_name" VARCHAR(30) NOT NULL,
  "description" VARCHAR(500),
  CONSTRAINT "unique_topic_name" UNIQUE ("topic_name"),
  CONSTRAINT "non_empty_topic_name" CHECK(LENGTH(TRIM("topic_name"))>0)
 );
CREATE INDEX "topic_name_index" ON "topics" ("topic_name");