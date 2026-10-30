
WITH  CustomerChain AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, 
           cd.cd_gender, cd.cd_dep_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_dep_count DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_dep_count IS NOT NULL
    UNION ALL
    SELECT cc.c_customer_sk, cc.c_first_name, cc.c_last_name, cd.cd_marital_status, 
           cd.cd_gender, cd.cd_dep_count,
           ROW_NUMBER() OVER (PARTITION BY cc.c_customer_sk ORDER BY cd.cd_dep_count ASC) AS rn
    FROM customer c
    JOIN customer cc ON c.c_customer_sk < cc.c_customer_sk
    JOIN customer_demographics cd ON cc.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M' AND cd.cd_dep_count < (
        SELECT MAX(cd2.cd_dep_count) 
        FROM customer c2
        JOIN customer_demographics cd2 ON c2.c_current_cdemo_sk = cd2.cd_demo_sk
        WHERE c2.c_customer_sk = c.c_customer_sk
    )
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT cc.c_customer_sk) AS Total_Customers,
    AVG(cd.cd_dep_count) AS Avg_Dependents,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS Married_Count
FROM CustomerChain cc
JOIN customer_address ca ON cc.c_customer_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cc.c_customer_sk = cd.cd_demo_sk
GROUP BY ca.ca_city, cc.c_first_name, cc.c_last_name, cd.cd_marital_status, cd.cd_gender, cd.cd_dep_count
HAVING AVG(NULLIF(cd.cd_dep_count, 0)) > 
           (SELECT AVG(cd2.cd_dep_count) FROM customer_demographics cd2 WHERE cd2.cd_gender = 'M')
ORDER BY Total_Customers DESC
LIMIT 10;
