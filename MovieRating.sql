CREATE DATABASE IF NOT EXISTS Movie;
USE Movie;
DROP TABLE movies;
# create table movie
CREATE TABLE movies 
    (movie_id INT(8) NOT NULL AUTO_INCREMENT PRIMARY KEY, 
     title VARCHAR(25) NOT NULL,
     year INT(4), 
     director VARCHAR(25)
    );
# insert values in movie
INSERT INTO movies
	(movie_id, title, year, director)
VALUES
	(101, 'Gone with the Wind', 1939, 'Victor Fleming'),
    (102, 'Star Wars', 1977, 'George Lucas'),
    (103, 'The Sound of Music', 1965, 'Robert Wise'),
    (104, 'E.T.', 1982, 'Steven Spielberg'),
    (105, 'Titanic', 1997, 'James Cameron'),
    (106, 'Snow White', 1937, 'NULL'),
    (107, 'Avatar', 2009, 'James Cameron'),
    (108, 'Raiders of the Lost Ark', 1981, 'Steven Spielberg');
# check the table content
SELECT *
FROM movies;

# create table reviewers
DROP TABLE reviewers;
CREATE TABLE reviewers
	(review_id INT(4),
     name VARCHAR(25)
     );
# insert values in the table
INSERT INTO reviewers
	(review_id, name)
VALUES
    (201, 'Sarah Martinez'),
    (202, 'Daniel Lewis'),
    (203, 'Brittany Harris'),
    (204, 'Mike Anderson'),
    (205, 'Chris Jackson'),
    (206, 'Elizabeth Thomas'),
    (207, 'James Cameron'),
    (208, 'Ashley White');

# create table ratings
CREATE TABLE ratings
	(review_id INT(4), 
     movie_id INT(4), 
     stars INT(4),
     ratingdate TIMESTAMP)
	;
# insert values in the table
INSERT INTO ratings
	(review_id, movie_id, stars, ratingdate)
VALUES
    (201, 101, 2, '2011-01-22'),
    (201, 101, 4, '2011-01-27'),
    (202, 106, 4,  NULL),
    (203, 103, 2, '2011-01-20'),
    (203, 108, 4, '2011-01-12'),
    (203, 108, 2, '2011-01-30'),
    (204, 101, 3, '2011-01-09'),
    (205, 103, 3, '2011-01-27'),  
    (205, 104, 2, '2011-01-22'),  
    (205, 108, 4,  NULL),  
    (206, 107, 3, '2011-01-15'),    
    (206, 106, 5, '2011-01-19'),    
    (207, 107, 5, '2011-01-20'),
    (208, 104, 3, '2011-01-02');

# Q0. view table content
SELECT *
FROM movies;
SELECT *
FROM reviewers;
SELECT *
FROM ratings;
# Q1.Remove duplicates for table ratings. We found some reviewers rate the same movie twice, 
# we will just keep the first time rating.
# create a copy of the table ratings
CREATE TABLE ratings_copy LIKE ratings;
INSERT INTO ratings_copy
	SELECT *
	FROM ratings;
# check duplicates records
SELECT review_id, movie_id, COUNT(*)
FROM ratings_copy
GROUP BY review_id, movie_id
HAVING COUNT(*)>1;
# Delete duplicates records
SET SQL_SAFE_UPDATES = 0;
DELETE r1 FROM ratings_copy r1
INNER JOIN ratings_copy r2
WHERE 
	r1.ratingdate > r2.ratingdate AND
    r1.review_id = r2.review_id AND
    r1.movie_id = r2.movie_id;
SET SQL_SAFE_UPDATES = 1;
# double check if duplicates records are deleted, should show nothing if successfully delete it.
SELECT review_id, movie_id, COUNT(*)
FROM ratings_copy
GROUP BY review_id, movie_id
HAVING COUNT(*)>1;
# drop table ratings, and rename ratings_copy to ratings
DROP TABLE ratings;
ALTER TABLE ratings_copy
RENAME TO ratings;
SELECT *
FROM ratings;

#Q2. Find the movie that reviwer gives the lowest star for each reviewer, 
# return the reviewer name, movie title, and number of stars. 
 WITH loweststar AS(
	SELECT rv.name, mv.title, rt.stars, 
    ROW_NUMBER() OVER (PARTITION BY rv.name ORDER BY rt.stars) AS movie_ranking
    FROM reviewers rv
    JOIN ratings rt
    ON rv.review_id = rt.review_id
    JOIN movies mv
    ON mv.movie_id = rt.movie_id
    ORDER BY movie_ranking
)
SELECT name, title, stars 
FROM loweststar
WHERE movie_ranking = 1;

# Q3. Find the movie that has the lowest stars in the database, 
# return the reviewer name, movie title, and number of stars. 
SELECT rv.name, mv.title, rt.stars
FROM ratings rt
JOIN reviewers rv
ON rt.review_id = rv.review_id
JOIN movies mv
ON rt.movie_id = mv.movie_id
WHERE rt.stars = (SELECT MIN(stars) 
				  FROM ratings
                  );

# Q4. Find the lowest star for each movie, return the reviewer name, movie title, and number of stars
WITH lowestrate AS (
	SELECT rv.name,mv.title,rt.stars,
    ROW_NUMBER() OVER (PARTITION BY mv.title ORDER BY rt.stars) AS lowest_star
    FROM ratings rt
    JOIN reviewers rv
    ON rt.review_id = rv.review_id
    JOIN movies mv
    ON rt.movie_id = mv.movie_id
    ORDER BY lowest_star
)
SELECT name, title, stars
FROM lowestrate
WHERE lowest_star = 1;

# Q5. List movie titles and avg ratings, from highest rated to lowest-rated. 
--  If two or more movies have the same avg rating, list them in alphabetical order. 
SELECT mv.title, avg(rt.stars)
FROM movies mv
JOIN ratings rt
ON mv.movie_id = rt.movie_id
GROUP BY mv.movie_id
ORDER BY avg(rt.stars) DESC, mv.title;

# Q6. Find the names of all reviewers who have contributed 3 or more ratings
SELECT rv.name, COUNT(*) AS rating_time
FROM reviewers rv
JOIN ratings rt
ON rv.review_id = rt.review_id
GROUP BY rv.name
HAVING COUNT(*) >= 3;

#Q7. Some directors directed more than 1 movie. For all such directors,
-- return the titles of all movies directed by them, along with the director name
-- sort by director name, then movie title
SELECT MIN(director), GROUP_CONCAT(title)
FROM movies
GROUP BY director
HAVING COUNT(*) > 1;

# 