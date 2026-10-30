
SELECT 
    COUNT(*) AS total_returns,
    SUM(sr_return_quantity) AS total_return_quantity,
    AVG(sr_return_amt) AS average_return_amount,
    MAX(sr_return_time_sk) AS latest_return_time
FROM 
    store_returns
WHERE 
    sr_returned_date_sk BETWEEN 20230101 AND 20231231
GROUP BY 
    sr_store_sk
ORDER BY 
    total_returns DESC;
