
SELECT 
    COUNT(*) AS total_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    cd_gender 
FROM 
    customer 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
GROUP BY 
    cd_gender;
