
WITH Address_City AS (
    SELECT DISTINCT ca_city
    FROM customer_address
    WHERE LENGTH(ca_city) > 5
), 
Customer_Info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IN (SELECT ca_city FROM Address_City)
), 
Aggregation AS (
    SELECT 
        ci.ca_city,
        COUNT(ci.c_customer_id) AS customer_count,
        SUM(CASE WHEN ci.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN ci.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(CASE WHEN ci.cd_marital_status = 'S' THEN 1 ELSE NULL END) AS single_ratio
    FROM Customer_Info ci
    GROUP BY ci.ca_city
),
Final_Output AS (
    SELECT 
        ca.ca_city,
        ca.customer_count,
        ca.male_count,
        ca.female_count,
        ROUND(ca.single_ratio * 100, 2) AS single_percentage
    FROM Aggregation ca
    WHERE ca.customer_count > 10
)
SELECT *
FROM Final_Output
ORDER BY ca_city;
