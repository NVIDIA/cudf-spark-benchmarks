
SELECT 
    COUNT(*) AS total_returns,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_quantity) AS avg_return_quantity,
    MAX(sr_return_time_sk) AS latest_return_time
FROM 
    store_returns
WHERE 
    sr_returned_date_sk > (
        SELECT 
            MAX(d_date_sk) 
        FROM 
            date_dim 
        WHERE 
            d_year = 2022
    )
GROUP BY 
    sr_reason_sk
ORDER BY 
    total_returns DESC;
