
SELECT 
    ca_city AS City,
    COUNT(DISTINCT c_customer_id) AS Unique_Customers,
    AVG(cd_purchase_estimate) AS Avg_Purchase_Estimate,
    MAX(cd_credit_rating) AS Highest_Credit_Rating
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    UPPER(ca_city) LIKE UPPER('%town%')
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    Unique_Customers DESC;
