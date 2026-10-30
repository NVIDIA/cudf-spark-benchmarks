
SELECT 
    COUNT(*) AS total_customers,
    AVG(cd_purchase_estimate) AS average_purchase_estimate
FROM 
    customer
JOIN 
    customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk;
