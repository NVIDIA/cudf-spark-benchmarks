
SELECT 
    CA.ca_city, 
    COUNT(DISTINCT C.c_customer_sk) AS Total_Customers, 
    SUM(CASE WHEN CD.cd_gender = 'F' THEN 1 ELSE 0 END) AS Female_Customers,
    SUM(CASE WHEN CD.cd_gender = 'M' THEN 1 ELSE 0 END) AS Male_Customers,
    AVG(CD.cd_purchase_estimate) AS Avg_Purchase_Estimate,
    MAX(CD.cd_credit_rating) AS Highest_Credit_Rating
FROM 
    customer_address CA
JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
GROUP BY 
    CA.ca_city
HAVING 
    COUNT(DISTINCT C.c_customer_sk) > 10
ORDER BY 
    Total_Customers DESC
LIMIT 20;
