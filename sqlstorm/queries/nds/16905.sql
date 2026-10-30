
SELECT 
    COUNT(*) AS total_customers, 
    COUNT(DISTINCT c_customer_id) AS distinct_customers 
FROM 
    customer;
