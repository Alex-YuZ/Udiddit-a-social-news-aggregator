DROP TABLE IF EXISTS "users" CASCADE;
DROP TABLE IF EXISTS "topics" CASCADE;
DROP TABLE IF EXISTS "posts" CASCADE;
DROP TABLE IF EXISTS "comments" CASCADE;
DROP TABLE IF EXISTS "votes" CASCADE;

-- Create Tables
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

-- Guidline #1: c.
CREATE TABLE "posts" (
  "id" SERIAL PRIMARY KEY,
  "title" VARCHAR(100) NOT NULL,
  "url" VARCHAR,
  "content" TEXT,
  "topic_id" INTEGER NOT NULL,
  "user_id" INTEGER,
  "created_at" TIMESTAMP WITH TIME ZONE,
     
  CONSTRAINT "non_empty_title" CHECK(LENGTH(TRIM("title"))>0),
     
  CONSTRAINT "url_or_text_check"
    CHECK ((LENGTH(TRIM("url"))=0 AND LENGTH(TRIM("content"))!=0) OR
           (LENGTH(TRIM("url"))!=0 AND LENGTH(TRIM("content"))=0)),
     
  CONSTRAINT "fkey_topic_id"
    FOREIGN KEY ("topic_id") REFERENCES "topics" ON DELETE CASCADE,
     
  CONSTRAINT "fkey_user_id"
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL
);
CREATE INDEX "latest_posts_given_topic" ON "posts" ("topic_id", "created_at");
CREATE INDEX "latest_posts_given_user" ON "posts" ("user_id", "created_at");
CREATE INDEX "url_moderation" ON "posts" ("url");

-- Guidline #1: d. Create "comments" table
CREATE TABLE "comments" (
  "id" SERIAL PRIMARY KEY,
  "content" TEXT NOT NULL,
  "post_id" INTEGER NOT NULL,
  "user_id" INTEGER,
  "parent_id" INTEGER,
  "created_at" TIMESTAMP WITH TIME ZONE,
     
  CONSTRAINT "non_empty_comment_text" CHECK (LENGTH(TRIM("content"))>0),
     
  CONSTRAINT "fkey_post_id"
    FOREIGN KEY ("post_id") REFERENCES "posts" ON DELETE CASCADE,
     
  CONSTRAINT "fkey_user_id"
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL,
     
  CONSTRAINT "fkey_comment_id"
    FOREIGN KEY ("parent_id") REFERENCES "comments" ON DELETE CASCADE
 );
CREATE INDEX "comments_given_parent" ON "comments" ("parent_id", "id");
CREATE INDEX "comments_given_user" ON "comments" ("user_id", "created_at");

-- Guidline #1: e. Create "votes" table
CREATE TABLE "votes" (
  "id" SERIAL PRIMARY KEY,
  "user_id" INTEGER,
  "post_id" INTEGER NOT NULL,
  "vote" SMALLINT,
     
  CONSTRAINT "uniqe_votes" UNIQUE ("user_id", "post_id"),
     
  CONSTRAINT "fkey_user_id"
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL,
     
  CONSTRAINT "fkey_post_id"
    FOREIGN KEY ("post_id") REFERENCES "posts" ON DELETE CASCADE,
     
  CONSTRAINT "vote_value_check" CHECK ("vote"= 1 OR "vote"= -1)
);


--Data Migration--
-- I. Migrate data into "users" from "bad_posts", "bad_comments"
INSERT INTO "users" ("user_name")
  (SELECT DISTINCT REGEXP_SPLIT_TO_TABLE("upvotes", ',') "user_name"
   FROM "bad_posts"

   UNION

   SELECT DISTINCT REGEXP_SPLIT_TO_TABLE("downvotes", ',') "user_name"
   FROM "bad_posts"

   UNION

   SELECT DISTINCT "username"
   FROM "bad_posts"

   UNION

   SELECT DISTINCT "username"
   FROM "bad_comments"
  );

-- II. Migrate data into "topics" table from "bad_posts"
INSERT INTO "topics" ("topic_name")
  SELECT DISTINCT topic FROM bad_posts;


-- III. Migrate data into "posts" table from "bad_posts"
INSERT INTO "posts" ("title", 
                     "url", 
                     "content", 
                     "topic_id", 
                     "user_id")
  SELECT SUBSTR("title",1,100), 
         "bp"."url", 
         "bp"."text_content", 
         "tp"."id", 
         "u"."id"
  FROM "bad_posts" "bp"
  JOIN "topics" "tp" ON "tp"."topic_name"="bp"."topic"
  JOIN "users" "u" ON "u"."user_name"="bp"."username";


-- IV. Migrate data into "votes" from "bad_posts" table
-- Extract all users who voted 'like'
INSERT INTO "votes" ("user_id", "post_id", "vote")
  SELECT "users"."id",
         "sub1"."post_id",
         1
  FROM (
        SELECT REGEXP_SPLIT_TO_TABLE("upvotes", ',') upvoters,
               "id" AS "post_id"
        FROM "bad_posts") sub1
  JOIN "users" ON "sub1"."upvoters"="users"."user_name";

-- Extract all users who voted 'dislike'
INSERT INTO "votes" ("user_id", "post_id", "vote")
  SELECT "users"."id",
         "sub1"."post_id",
         -1
  FROM (
        SELECT REGEXP_SPLIT_TO_TABLE("downvotes", ',') downvoters,
               "id" AS "post_id"
        FROM "bad_posts") sub1
  JOIN "users" ON "sub1"."downvoters"="users"."user_name";


-- V. Migrate data into "comments" from "bad_comments"
INSERT INTO "comments" ("content", "post_id", "user_id")
  SELECT "bad_comments"."text_content",
         "posts"."id",
         "users"."id"
  FROM "bad_comments"
  JOIN "posts" ON "posts"."id"="bad_comments"."post_id"
  JOIN "users" ON "users"."user_name"="bad_comments"."username";