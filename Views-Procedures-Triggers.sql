-- 1. For all buyers who bought at least 3 items after the date 2022-07-24, list each buyer’s user_id, first_name, and last_name.

SELECT U.user_id, U.first_name, U.last_name
FROM cs222p_interchange.user U
WHERE U.user_id IN (SELECT I.buyer_user_id
					FROM cs222p_interchange.item I
					WHERE I.purchase_date > '2022-07-24'
					GROUP BY I.buyer_user_id
					HAVING COUNT(*) >= 3)
					
-- same result
SELECT I.buyer_user_id, U.first_name, U.last_name
FROM cs222p_interchange.user U, cs222p_interchange.item I
WHERE (U.user_id = I.buyer_user_id) AND (I.purchase_date > '2022-07-24')
GROUP BY I.buyer_user_id, U.first_name, U.last_name
HAVING COUNT(I.item_id) >= 3
					


-- 2. [10pts] Find the highest price for each item sold by the seller with user id ‘S3AB0’ for each category of item where they’ve had sales. Print the item_id, item_name, category, and price of these highest-price items. Rank the output by price from highest to lowest.

-- subquery = max price per item category such that the item category has at least 1 sale (1 buyer_user_id)
								 
SELECT I.item_id, I.name, I.category, I.price
FROM cs222p_interchange.item I, (SELECT I2.category, MAX(I2.price) as max_price
								 FROM cs222p_interchange.item I2
								 WHERE I2.seller_user_id = 'S3AB0'
								 GROUP BY I2.category
								 HAVING COUNT(I2.buyer_user_id) > 0) AS Temp
WHERE I.seller_user_id = 'S3AB0' AND I.category = Temp.category AND I.price = Temp.max_price
ORDER BY I.price DESC



-- 3. For all unpurchased services that had an ad placed by its seller, list the seller’s user_id and the item_id, item_name, price, category, ad_id, ad_plan, and number of pictures associated with the item. Limit your output to the top 10 results ordered from highest to lowest by price.

-- item must be a service
-- item buyer_user_id IS NULL (unpurchased service)
-- there exists an ad_id for that item_id (if you know ad_id, you know exact item_id and exact seller_id)

-- 3A: For all unpurchased services that had an ad placed by its seller, list the seller’s user_id and the item_id, item_name, price, category, ad_id, ad_plan, and number of pictures associated with the item. Limit your output to the top 10 results ordered from highest to lowest by price.

SELECT Temp_1.seller_user_id, Temp_1.item_id, Temp_1.name, Temp_1.price, Temp_1.category, Temp_1.ad_id, Temp_1.plan, COALESCE(Temp_2.num_pics, 0) as num_pics

FROM (SELECT I.seller_user_id, I.item_id, I.name, I.price, I.category, A.ad_id, A.plan
	FROM cs222p_interchange.item I, cs222p_interchange.service S, cs222p_interchange.ad A
	WHERE (I.item_id = S.item_id) AND (I.buyer_user_id IS NULL) AND (I.purchase_date IS NULL) AND (I.item_id = A.item_id)) AS Temp_1

LEFT JOIN (SELECT P.item_id, COUNT(P.pic_num) as num_pics
FROM cs222p_interchange.picture P
GROUP BY P.item_id) Temp_2

ON Temp_1.item_id = Temp_2.item_id

ORDER BY Temp_1.price DESC
LIMIT 10


-- 4. It’s time to identify the highest rated sellers on the Interchange.com platform. To compute a seller’s overall rating we will sum up the individual quality, price, and delivery ratings and compute their average. If a particular rating attribute (quality, price, or delivery) is NULL, we will set a default value of 2.5 for that particular rating in the computation of the seller’s overall rating. We will classify a seller’s rating as “High” if that seller’s overall rating is at least 4.4 out of 5. If a seller’s overall rating  is at least 2.6 but under 4.4 we will classify that seller as “Medium”. If a seller’s overall rating is under 2.6 we will classify the seller as “Underdog”. In order to ensure that the ratings are accurate (and not spam or the result of a grudge) we will also indicate the number of ratings from users who have actually purchased items from the seller and call it the valid rating count.  To implement this we will create a view so that Interchange.com’s data analysts don’t have to deal with this complexity when working with the data. The view must include seller’s id, overall rating, seller classification, and valid rating count. 

-- 4A: Create the desired view – SellerOverallRating – by writing an appropriate CREATE VIEW statement. [HINT: Check out COALESCE, CASE, and WITHs in the PostGreSQL documentation).
CREATE VIEW SellerOverallRating (seller_id, overall_rating, classification, valid_rating_count) AS (
	SELECT overall_ratings.seller_id, 
	   overall_ratings.avg_rating AS overall_rating, 
	   
	   CASE
	   		 WHEN overall_ratings.avg_rating >= 4.4 
	   		 	  AND overall_ratings.avg_rating <= 5 THEN 'High'
			 WHEN overall_ratings.avg_rating >= 2.6 
			 	  AND overall_ratings.avg_rating < 4.4 THEN 'Medium'
			 WHEN overall_ratings.avg_rating < 2.6 THEN 'Underdog'	
	   END classification,
	   
	   COALESCE(valid_ratings.num_valid,0) as valid_rating_count
	   
FROM (SELECT R.seller_id, (SUM(COALESCE(R.quality, 2.5))+ SUM(COALESCE(R.pricing, 2.5)) + SUM(COALESCE(R.delivery, 2.5)))/(COUNT(*)*3) AS avg_rating
	  FROM cs222p_interchange.ratings R
	  GROUP BY R.seller_id) AS overall_ratings
	  
LEFT JOIN (SELECT R.seller_id, COUNT(R.buyer_id) as num_valid
	   FROM cs222p_interchange.ratings R
       WHERE EXISTS (SELECT *
		   	  		 FROM cs222p_interchange.item I
		      		 WHERE R.seller_id = I.seller_user_id AND R.buyer_id = I.buyer_user_id) 
	   GROUP BY R.seller_id) AS valid_ratings
	   
ON overall_ratings.seller_id = valid_ratings.seller_id
);



-- 4B: Show the usefulness of your view by writing a SELECT query against the view that prints the seller_id, first_name, last_name, and website of all sellers, also including their classification and valid rating count. Rank your results by the number of valid ratings from the highest to the lowest and limit the results to 5.

SELECT O.seller_id, U.first_name, U.last_name, S.website, O.classification, O.valid_rating_count
FROM SellerOverallRating O, cs222p_interchange.seller S, cs222p_interchange.user U
WHERE O.seller_id = S.user_id AND O.seller_id = U.user_id
ORDER BY O.valid_rating_count DESC
LIMIT 5


-- 5A: Create and exercise a SQL stored procedure called InsertServiceAndPlaceAd(...) that the application developer can use to simultaneously add a new Service and place an Ad for it.
CREATE PROCEDURE InsertServiceAndPlaceAd(
	IN seller_user_id text,
	IN item_name text,
	IN item_id text,
	IN service_frequency cs222p_interchange.Frequency,
	IN price float,
	IN category text,
	IN description text,
	IN ad_id text,
	IN plan text,
	IN content text,
	IN picture_url text,
	IN picture_format cs222p_interchange.PictureFormat
)
LANGUAGE SQL 
AS $$
	INSERT INTO cs222p_interchange.item(item_id, name, price, category, description, seller_user_id, list_date) 
	VALUES (item_id, item_name, price, category, description, seller_user_id, CURRENT_DATE);
	
	INSERT INTO cs222p_interchange.service(item_id, frequency) 
	VALUES (item_id, service_frequency);
	
	INSERT INTO cs222p_interchange.picture(pic_num, item_id, format, url) 
	VALUES (1, item_id, picture_format, picture_url);
	
	INSERT INTO cs222p_interchange.ad(ad_id, plan, content, pic_num, item_id, seller_user_id, placed_date) 
	VALUES (ad_id, plan, content, 1, item_id, seller_user_id, CURRENT_DATE);
	$$;

DROP PROCEDURE InsertServiceAndPlaceAd;

-- 5B: Verify that your stored procedure works properly by calling it as follows to insert a new Service Item with an associated Ad and running a SELECT query (or queries) to show the stored procedure’s after-effects.
CALL InsertServiceAndPlaceAd ('OE791', 'Yard Cleanup', 'yrdcleanup2022', 'weekly',  35.43, 'Paper, Cleaning, & Home', 'Cleanup services for yards done weekly', 'X2342YRD', 'Gold',  'Cleanup services for yards done weekly! Call Now!', 'https://yardworkforeveryone.net/pic1.png', 'png');

SELECT s.item_id, a.ad_id, i.seller_user_id, p.url
FROM cs222p_interchange.Service s, cs222p_interchange.Ad a, cs222p_interchange.Item i, cs222p_interchange.Picture p
WHERE s.item_id = p.item_id AND s.item_id = a.item_id AND i.item_id = s.item_id AND s.item_id='yrdcleanup2022';


-- 6A: Write and execute the ALTER TABLE statement(s) needed to modify the Ad table so that when an item associated with an Ad is deleted, the Ad will not also be deleted. It should now be retained instead.
ALTER TABLE cs222p_interchange.Ad
ALTER COLUMN item_id 
SET DEFAULT '';

ALTER TABLE cs222p_interchange.Ad
DROP CONSTRAINT ad_pic_num_item_id_fkey;

ALTER TABLE cs222p_interchange.Ad
ADD CONSTRAINT ad_item_id_fk 
FOREIGN KEY (item_id) REFERENCES cs222p_interchange.item(item_id)
ON DELETE SET DEFAULT;



-- 6B: Execute the following SELECT and DELETE statements to show the effect of your change. Report the COUNT query’s result (just the number) returned by the SELECT statement both before and after running your DELETE.
SELECT COUNT(*) FROM cs222p_interchange.Ad a WHERE a.item_id = 'CBAGZ';

DELETE FROM cs222p_interchange.Item WHERE item_id = 'CBAGZ';

SELECT COUNT(*) FROM cs222p_interchange.Ad a WHERE a.item_id = 'CBAGZ';


-- 7A: Create a new table TargetedAds(user_id, ad_id, PRIMARY KEY(user_id, ad_id)) that stores the Ads curated for the users based on a user’s indicated category of interests. Then write a CREATE TRIGGER statement (by hand of course!) to define a trigger that will do the following job: After a seller has placed an ad -- indicated by an insert into the Ad table -- if the category of the item for which the Ad was placed matches a user’s category of interest – as indicated by the user in the Categories table – the ad_id and the user’s user_id are added into the TargetedAds table. (The new table is only responsible for keeping the targeted ads for the user after the trigger is created.) Use the CREATE FUNCTION statement as well as needed. Your function should avoid inserting duplicate entries into the new table. (HINT: use “...ON CONFLICT...” to handle insertion conflicts.)

--DROP TABLE TargetedAds;

CREATE TABLE TargetedAds(
	user_id text, 
	ad_id text, 
	PRIMARY KEY (user_id, ad_id),
	FOREIGN KEY (user_id) REFERENCES cs222p_interchange.user(user_id) ON DELETE CASCADE,
	FOREIGN KEY (ad_id) REFERENCES cs222p_interchange.ad(ad_id) ON DELETE CASCADE
);


-- find the item the ad belongs to (only 1) --> find the category of the item in item table = AD Category
-- if user matches user_id and category = category in categories table, 
CREATE FUNCTION AddTargetAd()RETURNS TriggerAS $$	BEGIN		INSERT INTO TargetedAds(user_id, ad_id)
			SELECT C.user_id, NEW.ad_id	
		FROM cs222p_interchange.categories C
		WHERE C.category = (SELECT I.category
		 	   				FROM cs222p_interchange.ad A, cs222p_interchange.item I
		 	  				WHERE A.ad_id = NEW.ad_id AND A.item_id = I.item_id) ON CONFLICT DO NOTHING;	
		RETURN NEW;	END;$$LANGUAGE PLPGSQL;

CREATE TRIGGER TargetedAdsLoggerAFTER INSERT ON cs222p_interchange.AdFOR EACH ROWEXECUTE FUNCTION AddTargetAd();

--DROP FUNCTION AddTargetAd CASCADE;


-- 7B: Execute the following INSERT and SELECT statements to show the effect of your trigger. Report the results.
SELECT *
FROM TargetedAds
WHERE user_id = 'NS804';

--
INSERT INTO cs222p_interchange.Ad(ad_id, plan, content, pic_num, item_id, seller_user_id, placed_date)
VALUES ('ADT32457', 'Gold', 'New games available!', 1, 'F7E1N', '4Z5VC', '2022-11-06');


SELECT *
FROM TargetedAds
WHERE ad_id = 'ADT32457';

--

INSERT INTO cs222p_interchange.Categories (user_id, category)
VALUES ('YJLRR', 'Toys & Games');

INSERT INTO cs222p_interchange.Ad(ad_id, plan, content, pic_num, item_id, seller_user_id, placed_date)
VALUES ('ADT32458', 'Gold', 'New games available!', 1, 'F7E1N', '4Z5VC', '2022-11-06');

SELECT *
FROM TargetedAds
WHERE user_id = 'YJLRR';

--

UPDATE cs222p_interchange.Item SET category = 'Pet Care' WHERE item_id = 'IRFRO';

INSERT INTO cs222p_interchange.Ad(ad_id, plan, content, pic_num, item_id, seller_user_id, placed_date)
VALUES ('ADT32459', 'Gold', 'Pet Care Kit!', 1, 'IRFRO', '449OC', '2022-11-06');


SELECT *
FROM TargetedAds
WHERE ad_id = 'ADT32459'
LIMIT 10;
