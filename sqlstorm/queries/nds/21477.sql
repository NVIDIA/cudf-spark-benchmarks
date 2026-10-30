WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY wr_returned_date_sk DESC) AS rn
    FROM 
        web_returns
    WHERE 
        wr_return_quantity IS NOT NULL
), 
TotalSales AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_net_paid >= (SELECT AVG(ws_net_paid) FROM web_sales)
    GROUP BY 
        ws_ship_customer_sk
), 
ReturnSummary AS (
    SELECT 
        rr.wr_returning_customer_sk,
        SUM(rr.wr_return_quantity) AS total_returned_quantity,
        COUNT(rr.wr_returning_customer_sk) AS return_count
    FROM 
        RankedReturns rr
    GROUP BY 
        rr.wr_returning_customer_sk
    HAVING 
        SUM(rr.wr_return_quantity) > 0
)
SELECT 
    c.c_customer_id,
    ca.ca_city, 
    ts.total_net_paid,
    rs.total_returned_quantity,
    COALESCE(rs.return_count, 0) AS total_returns,
    CASE 
        WHEN ts.total_net_paid > 1000 THEN 'High Value'
        WHEN ts.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN rs.total_returned_quantity IS NULL THEN 'No Returns'
        WHEN rs.total_returned_quantity > 10 THEN 'Frequent Returns'
        ELSE 'Occasional Returns'
    END AS return_behavior
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    TotalSales ts ON c.c_customer_sk = ts.ws_ship_customer_sk
LEFT JOIN 
    ReturnSummary rs ON c.c_customer_sk = rs.wr_returning_customer_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND c.c_birth_year < (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - 21)
ORDER BY 
    customer_value DESC, 
    return_behavior ASC
LIMIT 100;