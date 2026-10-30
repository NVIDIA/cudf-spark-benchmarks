
SELECT 
    COUNT(*) AS total_customers,
    COUNT(DISTINCT c_customer_id) AS unique_customer_ids
FROM 
    customer;
