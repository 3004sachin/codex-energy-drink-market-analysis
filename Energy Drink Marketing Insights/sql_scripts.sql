USE energy_drink_survey;


-- Count how many rows are in each table.

-- Total respondents
SELECT COUNT(*) AS total_respondents FROM `dim_repondents`;
-- Total cities
SELECT COUNT(*) AS total_cities FROM dim_cities;
-- Total survey responses
SELECT COUNT(*) AS total_responses FROM fact_survey_responses;



-- Make sure primary keys are unique.
-- Check duplicate Respondent_IDs
SELECT `Respondent_ID`, COUNT(*) FROM `dim_repondents`
GROUP BY `Respondent_ID` 
HAVING COUNT(*) > 1

-- Check duplicate City_IDs
SELECT City_ID, COUNT(*) 
FROM dim_cities
GROUP BY City_ID
HAVING COUNT(*) > 1;

-- Check duplicate Response_IDs
SELECT Response_ID, COUNT(*) 
FROM fact_survey_responses
GROUP BY Response_ID
HAVING COUNT(*) > 1;
-- ---------------------------------------------------------------------------

-- 1. Demographic Insights (examples) 

-- a. Who prefers energy drink more?  (male/female/non-binary?)  
SELECT 
    d.Gender,
    COUNT(
        CASE f.Consume_frequency
            WHEN 'Daily' THEN 5
            WHEN '2-3 times a week' THEN 4
            WHEN 'Once a week' THEN 3
            WHEN '2-3 times a month' THEN 2
            WHEN 'Rarely' THEN 1
            ELSE 0
        END
    ) AS total_responses
FROM dim_repondents d
INNER JOIN fact_survey_responses f
    ON d.Respondent_ID = f.Respondent_ID
GROUP BY d.Gender
ORDER BY total_responses DESC;




-- b. Which age group prefers energy drinks more? 
SELECT 
    d.Age,
    COUNT(
        CASE f.Consume_frequency
            WHEN 'Daily' THEN 5
            WHEN '2-3 times a week' THEN 4
            WHEN 'Once a week' THEN 3
            WHEN '2-3 times a month' THEN 2
            WHEN 'Rarely' THEN 1
            ELSE 0
        END
    ) AS total_responses
FROM dim_repondents d
INNER JOIN fact_survey_responses f
    ON d.Respondent_ID = f.Respondent_ID
GROUP BY d.Age
ORDER BY total_responses DESC;


-- c. Which type of marketing reaches the most Youth (15-30)? 
SELECT 
     f.Marketing_channels, COUNT(*)total_youth_responses 
FROM dim_repondents d
INNER JOIN fact_survey_responses f
    ON d.Respondent_ID = f.Respondent_ID
WHERE d.Age IN ('15-18', '19-30')
GROUP BY f.Marketing_channels
ORDER BY total_youth_responses DESC;






-- 2. Consumer Preferences: 
-- -a. What are the preferred ingredients of energy drinks among respondents? 
SELECT ingredients_expected, COUNT(*) FROM fact_survey_responses 
GROUP BY ingredients_expected
ORDER BY COUNT(*) DESC 



-- -b. What packaging preferences do respondents have for energy drinks? 

SELECT Packaging_preference, COUNT(*) FROM fact_survey_responses 
GROUP BY Packaging_preference
ORDER BY COUNT(*) DESC 








-- 3. Competition Analysis: 
-- - a. Who are the current market leaders? 
SELECT 
    Current_brands,
    COUNT(*) AS brand_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_survey_responses),
        2
    ) AS market_share_percent
FROM fact_survey_responses
GROUP BY Current_brands
ORDER BY brand_count DESC;

-- b. What are the primary reasons consumers prefer those brands over ours?
SELECT 
    Reasons_for_choosing_brands,
    COUNT(*) AS respondents,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percent
FROM fact_survey_responses
WHERE Current_brands <> 'CodeX'
GROUP BY  Reasons_for_choosing_brands
ORDER BY respondents DESC;






-- 4. Marketing Channels and Brand Awareness: 
-- -a. Which marketing channel can be used to reach more customers? 
SELECT 
    Marketing_channels,
    COUNT(*) AS total_responses,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_survey_responses),
        2
    ) AS percent_reach
FROM fact_survey_responses
GROUP BY Marketing_channels
ORDER BY total_responses DESC;





--b. How effective are different marketing strategies and channels in reaching our customers? 
SELECT 
    f.Marketing_channels,
    COUNT(*) AS total_respondents,
    -- Awareness
    SUM(CASE WHEN f.Heard_before = 'Yes' THEN 1 ELSE 0 END) AS heard_count,
    -- Trial
    SUM(CASE WHEN f.Tried_before = 'Yes' THEN 1 ELSE 0 END) AS tried_count,
    -- Brand Perception
    SUM(CASE WHEN f.Brand_perception = 'Positive' THEN 1 ELSE 0 END) AS positive_count
FROM fact_survey_responses f
where Current_brands = 'CodeX'
GROUP BY f.Marketing_channels








--5. Brand Penetration: 
-- -a. What do people think about our brand? (overall rating) 
SELECT
    Brand_perception,
    COUNT(*) AS NumberOfRespondents,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_survey_responses)), 2) AS Percentage
FROM
    fact_survey_responses
    where Current_brands = 'CodeX'
GROUP BY
    Brand_perception
ORDER BY
    NumberOfRespondents DESC;


--b. Which cities do we need to focus more on? 
SELECT c.City,
COUNT(*) AS total_respondents,
    ROUND(SUM(CASE WHEN f.Heard_before = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Brand_Awareness_Percentage,
    ROUND(SUM(CASE WHEN f.Tried_before = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS tried_percent,
    ROUND(SUM(CASE WHEN f.Brand_perception = 'Negative' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.Respondent_ID), 2) AS Negative_Perception_Percentage,
    SUM(CASE WHEN f.Reasons_preventing_trying = 'Not available locally' THEN 1 ELSE 0 END) AS Availability_Issues
    from dim_repondents d 
    join fact_survey_responses f on d.Respondent_ID = f.Respondent_ID
    join dim_cities c on d.City_ID = c.City_ID
    where Current_brands = 'CodeX'
    GROUP BY c.City
ORDER BY
    Brand_Awareness_Percentage ASC,
    Negative_Perception_Percentage DESC;

--6. Purchase Behavior: 
-- -a. Where do respondents prefer to purchase energy drinks? 

SELECT Purchase_location, COUNT(*) AS respondents
FROM fact_survey_responses
GROUP BY Purchase_location
ORDER BY respondents DESC;



-- -b. What are the typical consumption situations for energy drinks among respondents? 
SELECT 
    Typical_consumption_situations,
    COUNT(*) AS total_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) 
                            FROM fact_survey_responses 
                            ),
        2
    ) AS percent_share
FROM fact_survey_responses
GROUP BY Typical_consumption_situations
ORDER BY total_count DESC;


-- c. What factors influence respondents' purchase decisions, such as price range and limited edition packaging? 
SELECT 
    Price_range,
    Limited_edition_packaging,
    COUNT(*) AS total_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_survey_responses),
        2
    ) AS percent_share

FROM fact_survey_responses
WHERE Price_range IS NOT NULL 
  AND Limited_edition_packaging IS NOT NULL
GROUP BY Price_range, Limited_edition_packaging
ORDER BY Price_range, total_count DESC;


-- 7. Product Development 
-- a. Which area of business should we focus more on our product development? (Branding/taste/availability) 
SELECT 
    Reasons_for_choosing_brands,
    COUNT(*) AS total_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_survey_responses WHERE Reasons_for_choosing_brands IS NOT NULL),
        2
    ) AS percent_share
FROM fact_survey_responses
where Current_brands = 'CodeX' and Reasons_for_choosing_brands not in ('Other', 'Effectiveness')
GROUP BY Reasons_for_choosing_brands
ORDER BY total_count DESC;


select Reasons_preventing_trying, count(Reasons_preventing_trying)
from fact_survey_responses
where Current_brands = 'CodeX'
group by Reasons_preventing_trying
order by count(Reasons_preventing_trying) desc;

SELECT Improvements_desired, COUNT(*) AS respondents
FROM fact_survey_responses
GROUP BY Improvements_desired
ORDER BY respondents DESC;
