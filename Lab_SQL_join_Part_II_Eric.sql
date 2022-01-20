USE sakila;

-- General check before we begin : is there a title that is the same for two different movie (distinct movie_id) ?
SELECT title, COUNT(DISTINCT(film_id)) as number_films_same_title
FROM sakila.film
GROUP BY title
HAVING number_films_same_title > 1;
-- No, that is never the case. So we will be able to count on unique titles or unique film_ids,
-- that will give the same result in the end


-- 1. Write a query to display for each store its store ID, city, and country.

SELECT * FROM store;
SELECT * FROM address;
SELECT * FROM city;
SELECT * FROM country;

SELECT s.store_id, ci.city, co.country
FROM sakila.store s
JOIN sakila.address a
USING (address_id)
JOIN sakila.city ci
USING (city_id)
JOIN sakila.country co
USING (country_id);

-- output 
-- 1 / Lethbridge / Canada
-- 2 / Woodridge / Australia

-- 2. Write a query to display how much business, in dollars, each store brought in.

SELECT * FROM sakila.store;
SELECT * FROM sakila.staff;
SELECT * FROM sakila.payment;

SELECT s1.store_id, SUM(p.amount) AS turnover
FROM sakila.store s1
JOIN sakila.staff s2
USING (store_id)
JOIN sakila.payment p
USING (staff_id)
GROUP BY s1.store_id;

-- output :
-- store 1 -> 33 489.47 $
-- store 2 -> 33 927.04 $


-- 3. Which film categories are longest?

-- Two ways to look at this : average duration per category or sum of the durations per category
-- I'll also take  the hypothesis that we want to look at the top 5 in each case
-- actually, there is a third version bonus, at the end

      -- 3.1. average duration
SELECT c.name AS category, round(AVG(f.length)) AS average_length
FROM sakila.category c
JOIN sakila.film_category fc
USING (category_id)
JOIN sakila.film f
USING (film_id)
GROUP BY category
ORDER BY average_length DESC
LIMIT 5;
-- output : Sports 128 / Games 128 / Foreign 122 / Drama 121 / Comedy 116

     -- 3.2. total duration of the category
SELECT c.name AS category, SUM(f.length) AS total_length
FROM sakila.category c
JOIN sakila.film_category fc
USING (category_id)
JOIN sakila.film f
USING (film_id)
GROUP BY category
ORDER BY total_length DESC
LIMIT 5;
-- output : Sports 9 487 / Foreign 8 884 / Family 7 920 / Games 7 798 / Drama 7 492


     -- 3.3. Just for fun
SELECT name, length(name) AS category_length
FROM sakila.category
ORDER BY category_length DESC
LIMIT 5;
-- output : documentary is the longest category, with 11 characters :-D


-- 4. Display the most frequently rented movies in descending order.

-- I'll assume that we want the answer at a film level, and not a "physical copy" level
-- I'll limit the output to the top 20 movies (to avoid showing 1 000 rows)

SELECT * FROM sakila.rental;
SELECT * FROM sakila.inventory;
SELECT * FROM sakila.film;

SELECT f.title, COUNT(r.rental_id) AS number_rentals
FROM sakila.film f
JOIN sakila.inventory i
USING (film_id)
JOIN sakila.rental r
USING (inventory_id)
GROUP BY f.title
ORDER BY number_rentals DESC
LIMIT 20;

-- output : Winner is "Bucket brotherhood" with 34 rentals
-- followed by "Rocketeer mother" with 33 rentals ...


-- 5. List the top five genres in gross revenue in descending order.

-- I'll assume "genre" is just another word for category, as I do not see any other data that woul match
SELECT c.name AS category, SUM(p.amount) AS gross_revenues
FROM sakila.category c
JOIN sakila.film_category fc
USING (category_id)
JOIN sakila.inventory i
USING (film_id)
JOIN sakila.rental r
USING (inventory_id)
JOIN sakila.payment p
USING (rental_id)
GROUP BY c.name
ORDER BY gross_revenues DESC
LIMIT 5;

-- output : winner is 'Sports' which generated 5 314.21 $ of gross revenues


-- 6. Is "Academy Dinosaur" available for rent from Store 1?

-- we need to check if a physical copy of the movie is available in the store.
-- if the last return date is after the last rental date, the movie will be available.
-- if the movie is not in the inventory od Store 1, the query should not return anything, I think...

SELECT * FROM sakila.film;
SELECT * FROM inventory;
SELECT * FROM rental;

SELECT f.title, MAX(r.rental_date) AS last_rental_date, MAX(r.return_date) AS last_return_date, i.store_id
FROM sakila.film f
JOIN sakila.inventory i
USING (film_id)
JOIN sakila.rental r
USING (inventory_id)
GROUP BY f.title
HAVING (f.title = 'Academy Dinosaur') AND (i.store_id = 1);

-- output, the file was last rented on 23-08-2005 and last returned on 30-08-2005
-- it is thus AVAILABLE for rent


-- 7. Get all pairs of actors that worked together.

-- I start here by creating, from table film_actor, a list of all the actor_id and the film_id they have worked for
-- Then I join this list with itself, joining the rows for which the film_id is the same, but the actor_id is
-- different. By doing just this, we obtain a list of all the pairs that have worked together, but they will appear
-- twice : for a pair in one movie, actor_id_1 will be paired with actor_id_2, but actor_id_2 will also be paired
-- with actor_id_1 again.
-- to avoid this, instead of applying actor_id_1 <> actor_id_2, I apply actor_id_1 > actor_id_2. This guaranties that
-- for all actors, we will only look at the rest of the actors list, as if a pair exist with an actor above him in
-- the list, this pair was already taken in the result when we looked at the other actor of the pair.
-- I then join that list twice with the actor table to get the first and last names of the actors.
-- To avoid confusion, I live the actor ID in the end result, as I have noticed that two actresses are exact
-- homonyms (first & last names)

SELECT * FROM actor;
SELECT * FROM film_actor;


SELECT 	pairs_list_2.actor_id_1,
		pairs_list_2.first_name_1,
		pairs_list_2.last_name_1,
        pairs_list_2.actor_id_2,
        a2.first_name AS first_name_2,
		a2.last_name AS last_name_2,
		pairs_list_2.films_together
FROM
(
	SELECT	pairs_list.actor_id_1,
			a.first_name AS first_name_1,
			a.last_name AS last_name_1,
			pairs_list.actor_id_2,
			pairs_list.films_together
	FROM
		(SELECT list1.actor_id AS actor_id_1, list2.actor_id AS actor_id_2, COUNT(DISTINCT(list1.film_id)) AS films_together
		FROM (SELECT actor_id, film_id
		FROM sakila.film_actor
		ORDER BY actor_id ASC) as list1
		JOIN (SELECT actor_id, film_id
		FROM sakila.film_actor
		ORDER BY actor_id ASC) as list2
		ON (list1.actor_id < list2.actor_id) AND (list1.film_id = list2.film_id)
		GROUP BY list1.actor_id, list2.actor_id) AS pairs_list
	JOIN sakila.actor a
	ON (pairs_list.actor_id_1 = a.actor_id)
	ORDER BY pairs_list.actor_id_1 ASC) AS pairs_list_2
JOIN sakila.actor a2
ON (pairs_list_2.actor_id_2 = a2.actor_id)
ORDER BY pairs_list_2.actor_id_1;


-- 8. Get all pairs of customers that have rented the same film more than 3 times.

-- let's check first if some customers have rented three times the same physical copy of a movie
SELECT customer_id, inventory_id, COUNT(rental_id) AS number_rentals
FROM sakila.rental
GROUP BY customer_id, inventory_id
HAVING number_rentals >= 3;
-- output is empty, so that never happened. But maybe they have rented various copies of the same movie (title or movie_id)
SELECT r.customer_id, f.title, COUNT(rental_id) AS number_rentals
FROM sakila.rental r
JOIN sakila.inventory i
USING (inventory_id)
JOIN sakila.film f
USING (film_id)
GROUP BY r.customer_id, f.title
HAVING number_rentals >= 3;
-- that has indeed happened four times, but, from the output never twice for the same movie.
-- if we self join this selection and filter on same movie but different customer_id, the result should thus be empty.

SELECT list1.customer_id, list2.customer_id, list1.title
FROM 
(SELECT r.customer_id, f.film_id, f.title, COUNT(rental_id) AS number_rentals
FROM sakila.rental r
JOIN sakila.inventory i
USING (inventory_id)
JOIN sakila.film f
USING (film_id)
GROUP BY r.customer_id, f.title
HAVING number_rentals >= 3) as list1
JOIN
(SELECT r.customer_id, f.film_id, f.title, COUNT(rental_id) AS number_rentals
FROM sakila.rental r
JOIN sakila.inventory i
USING (inventory_id)
JOIN sakila.film f
USING (film_id)
GROUP BY r.customer_id, f.title
HAVING number_rentals >= 3) as list2
ON (list1.customer_id <> list2.customer_id) AND (list1.film_id = list2.film_id);

-- indeed, returns an empty list





-- 9. For each film, list actor that has acted in more films.

-- for this, I start by creating a joining the film_actor table with itself, to create a list of film_id, actor_id
-- where I only keep the actors that have plaid in more than one movie
-- then I join this table to the film table to get the film titles and I finally join this last with the actor
-- table, to get the names of the actors.

SELECT selection2.title, a.first_name, a.last_name
FROM sakila.actor a
JOIN (
SELECT f.title, selection1.actor_id
FROM sakila.film f
JOIN (
SELECT fa1.film_id, fa1.actor_id
FROM sakila.film_actor fa1
JOIN sakila.film_actor fa2
ON (fa1.actor_id = fa2.actor_id) AND (fa1.film_id <> fa2.film_id)
GROUP BY fa1.film_id, fa1.actor_id ) selection1
ON (f.film_id = selection1.film_id)) selection2
ON a.actor_id = selection2.actor_id;