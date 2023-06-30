CREATE SCHEMA IF NOT EXISTS cs222p_hw;

-- TYPES -------------------------------------------------------------

CREATE TYPE frequency_type AS ENUM('once', 'daily', 'weekly', 'monthly', 'quarterly', 'yearly');
CREATE TYPE phone_type AS ENUM('mobile', 'home', 'work');
CREATE TYPE picture_format AS ENUM('png', 'jpeg', 'mp4');
CREATE TYPE plan_type AS ENUM('bronze', 'silver', 'gold', 'platinum');

-- ENTITY RELATIONS --------------------------------------------------

CREATE TABLE cs222p_hw.User
(
	user_id text,
	email text NOT NULL,
	address_street text,
	address_city text,
	address_state text,
	address_zip integer,
	categories text,
	joined_date timestamp NOT NULL,
	name_first text,
	name_last text NOT NULL,
	UNIQUE (email),
	PRIMARY KEY (user_id)
);

CREATE TABLE cs222p_hw.User_phones
(
	uid text,
	phone_number integer,
	phone_kind phone_type,
	PRIMARY KEY (uid, phone_number),
	FOREIGN KEY (uid) REFERENCES cs222p_hw.User(user_id) ON DELETE CASCADE 
);


CREATE TABLE cs222p_hw.Buyer
(
	uid text,
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES cs222p_hw.User(user_id) ON DELETE CASCADE -- need to specify bc IsA
);

CREATE TABLE cs222p_hw.Seller
(
	uid text,
	website text,
	PRIMARY KEY (uid),
	FOREIGN KEY (uid) REFERENCES cs222p_hw.User(user_id) ON DELETE CASCADE -- need to specify bc IsA
); 


CREATE TABLE cs222p_hw.Ad
(
	ad_id text,
	suid text NOT NULL, -- placed rltshp folded in
	plan plan_type NOT NULL,
	content text,
	placed_date timestamp NOT NULL, -- placed rltshp folded in
	PRIMARY KEY (ad_id),
	FOREIGN KEY (suid) REFERENCES cs222p_hw.Seller(uid) ON DELETE CASCADE -- placed rltshp folded in
);


CREATE TABLE cs222p_hw.Item
(
	item_id text,
	buid text, -- buys rltshp folded in
	name text NOT NULL,
	price integer NOT NULL,
	category text NOT NULL,
	description text,
	purchase_date timestamp NOT NULL, -- buys rltshp folded in
	FOREIGN KEY (buid) REFERENCES cs222p_hw.Buyer(uid) ON DELETE SET NULL, -- buys rltshp folded in
	PRIMARY KEY (item_id)
);


CREATE TABLE cs222p_hw.Picture
(
	pic_num integer NOT NULL,
	iid text NOT NULL, -- view rltshp folded in
	format picture_format NOT NULL,
	url text NOT NULL,
	PRIMARY KEY (pic_num, iid), -- both are required for weak entity set case !
	FOREIGN KEY (iid) REFERENCES cs222p_hw.Item(item_id) ON DELETE CASCADE -- view rltshp folded in
);


CREATE TABLE cs222p_hw.Good
(
	iid text,
	PRIMARY KEY (iid),
	FOREIGN KEY (iid) REFERENCES cs222p_hw.Item(item_id) ON DELETE CASCADE -- need to specify bc IsA
);



CREATE TABLE cs222p_hw.Service
(
	iid text,
	frequency frequency_type NOT NULL,
	PRIMARY KEY (iid),
	FOREIGN KEY (iid) REFERENCES cs222p_hw.Item(item_id) ON DELETE CASCADE -- need to specify bc IsA
);




-- RELATIONSHIP RELATIONS --------------------------------------------

CREATE TABLE cs222p_hw.Ratings
(
	buid text,
	suid text,
	quality integer,
	pricing integer,
	delivery integer,
	rating_date date NOT NULL,
	PRIMARY KEY (buid, suid),
	FOREIGN KEY (buid) REFERENCES cs222p_hw.Buyer(uid) ON DELETE SET NULL, 
 	FOREIGN KEY (suid) REFERENCES cs222p_hw.Seller(uid) ON DELETE CASCADE
);

CREATE TABLE cs222p_hw.Sells
(
	suid text NOT NULL,
	iid text,
	list_date date NOT NULL,
	PRIMARY KEY (iid), -- N side
	FOREIGN KEY (suid) REFERENCES cs222p_hw.Seller(uid) ON DELETE CASCADE,
	FOREIGN KEY (iid) REFERENCES cs222p_hw.Item(item_id) ON DELETE SET NULL
);


CREATE TABLE cs222p_hw.About
(
	iid text NOT NULL,
	ad_id text,
	PRIMARY KEY (ad_id), -- N side
	FOREIGN KEY (iid) REFERENCES cs222p_hw.Item(item_id) ON DELETE CASCADE,
	FOREIGN KEY (ad_id) REFERENCES cs222p_hw.Ad(ad_id) ON DELETE CASCADE

);

CREATE TABLE cs222p_hw.Use
(
	pic_num integer NOT NULL,
	iid text NOT NULL,
	ad_id text,
	PRIMARY KEY (ad_id), -- N side 
	FOREIGN KEY (pic_num, iid) REFERENCES cs222p_hw.Picture(pic_num, iid) ON DELETE CASCADE,
	FOREIGN KEY (ad_id) REFERENCES cs222p_hw.Ad(ad_id)
);

