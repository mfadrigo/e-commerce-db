-- IMPORTANT: Be sure that the results of your queries do not contain duplicate records.

-- 1 Find the item ids of the item with the name ‘Laptop’ and limit your results to the top 5 costliest items. 
SELECT I2.item_id
FROM (SELECT DISTINCT I.price, I.item_id
FROM cs222p_interchange.item I 
WHERE I.name = 'Laptop'
ORDER BY I.price DESC
LIMIT 5) AS I2


-- 2 List the email of the sellers whose last name was ‘Taylor’
SELECT DISTINCT(U.email)
FROM cs222p_interchange.user U
WHERE U.last_name = 'Taylor'


-- 3 Select the first and last names of users who bought an item with the name ‘Hoodie’. Sort the results in ascending order based on the first name 
SELECT DISTINCT U.first_name, U.last_name
FROM cs222p_interchange.user U, cs222p_interchange.item I
WHERE U.user_id = I.buyer_user_id AND I.name = 'Hoodie'
ORDER BY U.first_name ASC


-- 4 List the user_id of the buyer who rated a seller who sells an item with item_id  ‘G9WMY’. Order the results in descending order of the seller’s quality rating.
SELECT R2.buyer_id
FROM (SELECT DISTINCT R.buyer_id, R.quality
FROM cs222p_interchange.ratings R, cs222p_interchange.item I
WHERE R.seller_id = I.seller_user_id AND I.item_id = 'G9WMY' 
ORDER BY R.quality DESC) AS R2


-- 5 List the user emails and first names of users who bought at least one item of the category "Clothing, Shoes & Jewelry" or "Toys & Games"  on the platform and who live in the city “Josephstad”.
SELECT DISTINCT U.email, U.first_name
FROM cs222p_interchange.user U, cs222p_interchange.item I
WHERE (U.user_id = I.buyer_user_id) AND (I.category = 'Clothing, Shoes & Jewelry' OR  I.category = 'Toys & Games') AND (U.city = 'Josephstad')



-- 6 List the emails, first names, and last names of users who are both a buyer and a seller on the platform and who are a resident of the state ‘West Virginia and order the results using zipcode in ascending order
SELECT Z.email, Z.first_name, Z.last_name
FROM (SELECT DISTINCT U.zip, U.email, U.first_name, U.last_name
FROM cs222p_interchange.user U, cs222p_interchange.buyer B, cs222p_interchange.seller S
WHERE (U.user_id = B.user_id) AND (U.user_id = S.user_id) AND (U.state = 'West Virginia')
ORDER BY U.zip ASC) AS Z

-- 7 List the ad ids of advertisements that have a picture with a pic_num of ‘2’ and are associated with an item of the category ‘Electronics’ with a price under 1000. Order the results by ad_id in ascending order and limit the results to 5 records
SELECT DISTINCT(A.ad_id)
FROM cs222p_interchange.ad A, cs222p_interchange.picture P, cs222p_interchange.item I
WHERE (A.item_id = P.item_id) AND (P.pic_num = '2') AND (A.item_id = I.item_id) AND (I.category = 'Electronics') AND (I.price < 1000)

-- 8 List the mobile phone numbers (i.e., of kind ‘MOBILE’) of all the sellers who listed items on the platform on the date “2022-07-17”. Limit your output to 10 records 
SELECT M.number
FROM cs222p_interchange.Phone as M
WHERE M.kind = 'mobile' and M.user_id IN (SELECT I.seller_user_id
										  FROM cs222p_interchange.Item as I 
										  WHERE I.list_date = '2022-07-17' 
										  LIMIT 10)