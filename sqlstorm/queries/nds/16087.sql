
SELECT 
    COUNT(*) AS total_customers,
    cd_gender,
    cd_marital_status
FROM 
    customer 
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
GROUP BY 
    cd_gender, cd_marital_status;
