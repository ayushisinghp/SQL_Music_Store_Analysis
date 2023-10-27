-- Q1: Who is the senior most employee based on the job title?
 
 Select * from employee
 ORDER BY levels desc
 LIMIT 1;
 --  Q2: Which countries have the most invoices?
 
select count(*) as c, billing_country 
from invoice
GROUP BY billing_country
ORDER BY c desc;
 
--  Q3: What are the top 3 values of total invoice?
 
 select total from invoice
 ORDER BY total desc
 LIMIT 3;
 ;
 
 /* Q4: Which city has the best customers? We would like to throw a promotional Music Festival 
in the city we made the most money. Write a query that returns one city that has the highest 
sum of invoice totals. Return both the city name & sum of all invoice totals */

select billing_city,sum(total) as invoice_total from invoice
GROUP BY billing_city
ORDER BY invoice_total desc
LIMIT 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared 
the best customer. Write a query that returns the person who has spent the most money.*/
select c.customer_id,c.first_name,c.last_name,SUM(i.total) as total from customer c
inner join invoice i on c.customer_id=i.customer_id
GROUP BY c.customer_id
ORDER BY total desc
limit 1;


/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

-- Method 1:
select distinct customer.email,customer.first_name,customer.last_name
from customer 
inner join invoice on customer.customer_id=invoice.customer_id
inner join Invoice_Line on Invoice_line.Invoice_id=invoice.invoice_id
inner join Track on  track.track_id=Invoice_line.track_id
inner join genre on genre.genre_id=track.genre_id
where genre.name LIKE 'Rock'
order by customer.email;

-- Method 2
Select distinct customer.email, customer.first_name, customer.last_name from customer
inner join invoice 
on customer.customer_id=invoice.customer_id
inner join Invoice_Line on
Invoice_Line.invoice_id=invoice.invoice_id
WHERE track_id in (select track.track_id from track
				 inner join genre 
				 on track.genre_id=genre.genre_id
				  where genre.name like 'Rock')
				  order by customer.email;


/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select Artist.artist_id,Artist.name,count(artist.artist_id) as number_of_songs from track
inner join album on track.album_id=album.album_id
inner join Artist  on album.artist_id=artist.artist_id
inner join genre on genre.genre_id=track.genre_id
where genre.name like 'Rock'
group by Artist.artist_id
order by number_of_songs desc
LIMIT 10;

/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs 
listed first. */
select name,milliseconds from track where
milliseconds >(
select AVG(milliseconds) from track)
order by milliseconds desc;
/* Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name 
and total spent */
with best_selling_artist As(
	Select artist.artist_id,artist.name as artist_name,SUM(invoice_line.unit_price*invoice_line.quantity) as amount
	from invoice_line 
	inner join track on invoice_line.track_id=track.track_id
	inner join album on track.Album_id=album.Album_id
	inner join artist on artist.Artist_id=album.Artist_id
	GROUP BY 1
	ORDER BY amount desc
	LIMIT 1
	)
select customer.customer_id,customer.first_name,customer.last_name,bsa.artist_name,
SUM(invoice_line.unit_price*invoice_line.quantity) as ampunt_spent
	from customer
	inner join invoice on customer.customer_id=invoice.customer_id
	inner join invoice_line on invoice.invoice_id=invoice_line.invoice_id
	inner join track on  invoice_line.track_id=track.track_id
	inner join album on track.album_id=album.album_id
	inner join best_selling_artist bsa on album.artist_id=bsa.artist_id
	group by 1,2,3,4
	order by 5 desc;
	

/* Q10: We want to find out the most popular music Genre for each country. We determine the most popular genre as
the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres. */

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1


-- Method 2

WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

/* Q11: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */
WITH RECURSIVE 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;

