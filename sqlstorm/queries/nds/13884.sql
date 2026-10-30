
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    AVG(cd_purchase_estimate) AS average_purchase_estimate
FROM 
    customer_demographics
JOIN 
    customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
WHERE 
    customer.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    customer.c_current_cdemo_sk;
