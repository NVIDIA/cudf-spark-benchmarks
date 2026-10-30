
SELECT 
    COUNT(*) AS total_customers, 
    AVG(cd_dep_count) AS average_dependents 
FROM 
    customer 
JOIN 
    customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk 
WHERE 
    cd_gender = 'F' 
GROUP BY 
    cd_marital_status;
