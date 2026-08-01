USE population;

SELECT * FROM population_by_age_group;

ALTER TABLE population_by_age_group
RENAME COLUMN Entity TO Country;

ALTER TABLE population_by_age_group
RENAME COLUMN `Under-5s` TO `Under-5`;

CREATE TABLE population_by_age_group_bewerkt like population_by_age_group;

INSERT INTO population_by_age_group_bewerkt
SELECT * FROM population_by_age_group;

SELECT * FROM population_by_age_group_bewerkt;

DESCRIBE population_by_age_group_bewerkt;

ALTER TABLE population_by_age_group_bewerkt
MODIFY COLUMN `Ages 65+` INT,
MODIFY COLUMN `Ages 15-24` INT,
MODIFY COLUMN `Ages 5-14` INT;

DESCRIBE population_by_age_group_bewerkt;

# we kunnen drie categorieeen 0nderscheiden in de kolom Country
# 1. afzonderlijke landen (bijv. Afghanistan,Belgium, Canada etc.). Deze landen hebben een 3-letterige code 2. Landen die geen code hebben zijn geen afzonderlijke landen, maar Categorieen naar ontwikkelingsgraad: (Americas (UN), Land-locked developping Countries (LLDC), least developped countries, less developed regions, less developed regions (excluding China, less developed regions (excluding least developped countries),
# More developped regions, small island developped states (Sids). Het is niet altijd duidelijk welke landen oprollen naar deze categorieen. 3. Landen die een code hebben die langer is dan drie karakters zijn ook geen afzonderlijke landen maar werelddelen of inkomensgroepen. 
# Derhalve zal de verdere analyse opgesplitst worden in 3 delen. Deel 1. afzonderlijke landen en deel 2. Categorieen naar ontwikkelingsgraad en 3 werelddelen of inkomensgroepen.
# In een later stadium gaan we deze verdeling visualiseren in PowerBI, daar zullen we een aparte kolom aanmaken.

SELECT DISTINCT COUNTRY FROM population_by_age_group_bewerkt;

#236 afzonderlijke landen
SELECT count(distinct Country) FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3;

SELECT DISTINCT Code FROM population_by_age_group_bewerkt;

SELECT Country, Code FROM population_by_age_group_bewerkt
where Code IS NULL;

SELECT Country, Code FROM population_by_age_group_bewerkt
where Code = '';

SELECT Country, Code FROM population_by_age_group_bewerkt
where CHAR_LENGTH(Code) = 3;

#blanke cellen in kolom Code is niet NULL maar een lege string, dus
SELECT DISTINCT * FROM population_by_age_group_bewerkt
where Code = '';

#overzicht totale hoeveelheid tot.ages per jaar
SELECT distinct Year, Tot_Ages FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3
order by Tot_Ages desc;



# selecten van Categorieen naar ontwikkelingsgraad en werelddelen/inkomensgroepen
SELECT distinct Country, Code FROM population_by_age_group_bewerkt
WHERE Code = '' or CHAR_LENGTH(Code) > 3;

#Er zijn geen waarden in de kolom year met afwijkende notaties
SELECT DISTINCT Year FROM population_by_age_group_bewerkt;

#kolom creeren met totaal waarde van de 5 leeftijdcategorien
ALTER TABLE population_by_age_group_bewerkt
ADD COLUMN Tot_Ages INT;

UPDATE population_by_age_group_bewerkt
SET Tot_Ages =
    COALESCE(`Under-5`, 0) +
    COALESCE(`Ages 5-14`, 0) +
    COALESCE(`Ages 15-24`, 0) +
    COALESCE(`Ages 25-64`, 0) +
    COALESCE(`Ages 65+`, 0) ;

DESCRIBE population_by_age_group_bewerkt;

#type van nw gecreeerde kolom wijzigen naar BIGINT. Datatype interval kan de hoeveelheid getallen niet omvatten
ALTER TABLE population_by_age_group_bewerkt
MODIFY COLUMN Tot_Ages BIGINT;


#ook nwe kolommen creeren voor iedere leeftijdcat met percentage van het totaal
ALTER TABLE population_by_age_group_bewerkt
ADD COLUMN `% 65+` INT,
ADD COLUMN `% 25-64` INT,
ADD COLUMN `% 15-24` INT,
ADD COLUMN `% 5-14` INT,
ADD COLUMN `% under 5` INT;

UPDATE population_by_age_group_bewerkt
SET `% 65+` = ROUND(( `Ages 65+`/`Tot_Ages`)* 100, 0) ,
	`% 25-64` = ROUND((`Ages 25-64`/`Tot_Ages`) * 100, 0),
     `% 15-24` = ROUND((`Ages 15-24`/`Tot_Ages`)* 100, 0),
     `% 5-14` = ROUND((`Ages 5-14`/`Tot_Ages`)* 100, 0),
	 `% under 5` = ROUND((`Under-5`/`Tot_Ages`) * 100,0); 
     
#controleren aantal rijen in tabel (19280)
SELECT *, row_number() OVER() as Row_Num FROM population_by_age_group_bewerkt
ORDER BY Row_Num DESC;

#controleren of er duplicaten zijn en die zijn er niet
SELECT *, row_number() OVER(partition by Country, Code, Year) as Row_Num FROM population_by_age_group_bewerkt;

WITH Duplicate_cte as
(SELECT *, row_number() OVER(partition by Country, Code, Year) as Row_Num FROM population_by_age_group_bewerkt)
SELECT * FROM Duplicate_cte
WHERE Row_Num >1;

#analyse
#543 regels voor landen zonder code
SELECT COUNT(*)
FROM population_by_age_group_bewerkt
WHERE Code = '';

#1273 regels voor landen zonder code
SELECT COUNT(*)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) > 3;

#17464 regels voor afzonderlijke landen. Veruit de meeste
SELECT COUNT(*)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3;

#leeftijdsverdeling berekenen voor de 3 categorien (in in PowerBI worden de verdelingen gevisualiseerd)
SELECT Country, Year, `Tot_Ages`, `% 65+`, `% 25-64`, `% 15-24`, `% 5-14`, `% under 5`
FROM population_by_age_group_bewerkt
WHERE Code = '' and year > 2021;

SELECT Round(AVG(`% 65+`),2), Round(AVG(`% 25-64`),2),  Round(AVG(`% 15-24` ),2),  Round(AVG(`% 5-14`),2),  Round(AVG(`% under 5`),2)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) > 3;

SELECT Country, Year,`Tot_Ages`, `% 65+`, `% 25-64`,  `% 15-24`, `% 5-14`,  `% under 5`
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) > 3 and year = 2023
ORDER BY `% 65+` DESC;

#Verderdeling Top tien landen met gemiddeld meeste 65+
SELECT Country, Round(AVG(`Tot_Ages`),0), Round(AVG(`% 65+`),1), Round(AVG(`% 25-64`),1),  Round(AVG(`% 15-24` ),1),  Round(AVG(`% 5-14`),1),  Round(AVG(`% under 5`),1)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and year > 2020
GROUP BY Country
ORDER BY AVG(`% 65+`) DESC
LIMIT 20;

#Verdeling Top tien landen met gemiddeld minste 65+
SELECT Country, Round(AVG(`Tot_Ages`),0), Round(AVG(`% 65+`),1), Round(AVG(`% 25-64`),1),  Round(AVG(`% 15-24` ),1),  Round(AVG(`% 5-14`),1),  Round(AVG(`% under 5`),1)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and year > 2020
GROUP BY Country
ORDER BY AVG(`% 65+`) ASC
LIMIT 10;

#Verdeling leeftijdscategorien Nederland
SELECT Year, Country, `Tot_Ages`, `% 65+`, `% 25-64`, `% 15-24`, `% 5-14`, `% under 5`
FROM population_by_age_group_bewerkt
WHERE Country LIKE '%Net%';

#Top tien landen met gemiddeld meeste kinderen onder 5 vanaf 2020
SELECT Country, Round(AVG(`Tot_Ages`),0), Round(AVG(`% 65+`),1), Round(AVG(`% 25-64`),1),  Round(AVG(`% 15-24` ),1),  Round(AVG(`% 5-14`),1),  Round(AVG(`% under 5`),1)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and Year > 2020
GROUP BY Country
ORDER BY AVG(`% under 5`) DESC
LIMIT 10;

#Top tien landen met gemiddeld minste kinderen onder 5 vanaf 2020
SELECT Country, Round(AVG(`Tot_Ages`),0), Round(AVG(`% 65+`),1), Round(AVG(`% 25-64`),1),  Round(AVG(`% 15-24` ),1),  Round(AVG(`% 5-14`),1),  Round(AVG(`% under 5`),1)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and Year > 2020
GROUP BY Country
ORDER BY AVG(`% under 5`) ASC
LIMIT 10;

#Top tien landen met gemiddeld meeste 15 tot 24 jarigen vanaf 2020
SELECT Country, Round(AVG(`% 65+`),1), Round(AVG(`% 65+`),1), Round(AVG(`% 25-64`),1),  Round(AVG(`% 15-24` ),1),  Round(AVG(`% 5-14`),1),  Round(AVG(`% under 5`),1)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and Year > 2020
GROUP BY Country
ORDER BY AVG(`% 15-24`) DESC
LIMIT 10;

#Top tien landen met gemiddeld minste 15 tot 24 jarigen vanaf 2020
SELECT Country, Round(AVG(`% 65+`),1), Round(AVG(`% 65+`),1), Round(AVG(`% 25-64`),1),  Round(AVG(`% 15-24` ),1),  Round(AVG(`% 5-14`),1),  Round(AVG(`% under 5`),1)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and Year > 2020
GROUP BY Country
ORDER BY AVG(`% 15-24`) ASC
LIMIT 10;

#Overzicht leeftijdsverdeling naar ontwikkelingsregio vanaf 2020
SELECT Country, year, `Tot_Ages`, `% 65+`, `% 25-64`,  `% 15-24`, `% 5-14`,  `% under 5`
FROM population_by_age_group_bewerkt
WHERE Code = '' and year > 2020
ORDER BY `% 65+` DESC;

#Overzicht leeftijdsverdeling naar inkomensniveau in 2023
SELECT Country, `Tot_Ages`, `% 65+`, `% 25-64`,  `% 15-24`, `% 5-14`,  `% under 5`
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) > 3 and year = 2023
ORDER BY `% 65+` DESC;

#overzicht gemiddelde leeftijdverdeling van alle landen
SELECT Country,Round(AVG(`% 65+`),1), Round(AVG(`% 65+`),1), Round(AVG(`% 25-64`),1),  Round(AVG(`% 15-24` ),1),  Round(AVG(`% 5-14`),1),  Round(AVG(`% under 5`),1)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3
GROUP BY Country
ORDER BY AVG(`% 65+`) DESC;

#Top tien landen met perc meeste 65% ongeacht jaar
SELECT Country, max(`% 65+`)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3
GROUP BY Country
ORDER BY max(`% 65+`) DESC
LIMIT 10;

#Top tien landen met perc minste 65% ongeacht jaar
SELECT Country,  min(`% 65+`)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3
GROUP BY Country
ORDER BY min(`% 65+`) ASC
LIMIT 10;

#Top tien jaren met perc meeste 65%. Vaticaan is 10 jaren achtereen de winnaar. Group by is hierbij niet nodig want er is maar 1 rij per combinatie van land en jaar
SELECT Year, Country, max(`% 65+`)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3
GROUP BY Year, Country
ORDER BY  max(`% 65+`) DESC
LIMIT 10;

#bovenstaande code is incorrect want group by is niet nodig
SELECT Year, Country,  `Tot_Ages`, `Ages 65+`, `% 65+`
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3
ORDER BY  `% 65+` DESC
LIMIT 10;

#Top tien jaren met perc meeste 65+. UAE is 10 jaren de winnaar. Group by is hierbij niet nodig want er is maar 1 rij per combinatie van land en jaar
SELECT Year, Country, max(`% 65+`)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3
GROUP BY Year, Country
ORDER BY  max(`% 65+`) ASC
LIMIT 10;


#bovenstaande code is incorrect want group by is niet nodig
SELECT Year, Country, `Tot_Ages`,`Ages 65+`, `% 65+`
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3
ORDER BY  `% 65+` ASC
LIMIT 10;

#leeftijdsVerdeling UAE 
SELECT Year, Country, `Tot_Ages`,`Ages 65+`, `% 65+`
FROM population_by_age_group_bewerkt
WHERE Country = 'United Arab Emirates';

#Top tien landen met perc meeste 25 to 24 jarigen vanaf 2020
SELECT Country,  max(`% 25-64`)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and year>2020
GROUP BY Country
ORDER BY  max(`% 25-64`) DESC
LIMIT 10;

#Top tien landen met perc meeste 15 to 24 jarigen vanaf 2020
SELECT Country,  max(`% 15-24`)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and year>2020
GROUP BY Country
ORDER BY  max(`% 15-24`) DESC
LIMIT 10;

#Top tien landen met perc meeste 5 tot 14 jarigen vanaf 2020
SELECT Country, max(`% 5-14`)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and year > 2020
GROUP BY Country
ORDER BY  max(`% 5-14`) DESC
LIMIT 10;

#Top tien landen met perc minste 5 tot 14 jarigen vanaf 2020
SELECT Country, min(`% 5-14`)
FROM population_by_age_group_bewerkt
WHERE CHAR_LENGTH(Code) = 3 and year > 2020
GROUP BY Country
ORDER BY  min(`% 5-14`) asc
LIMIT 10;

#nw kolom creeeren met unieke combinatie van code en year die ik waarschijnlijk in Power Bi ga gebruiken om te joinen  
ALTER TABLE population_by_age_group_bewerkt
ADD COLUMN `Code_Year` TEXT;


UPDATE population_by_age_group_bewerkt
SET `Code_Year` = CONCAT(Code, '_', Year);


SELECT * FROM population_by_age_group_bewerkt;

