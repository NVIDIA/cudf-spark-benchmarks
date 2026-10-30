
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    AND 
        c.c_birth_year BETWEEN 1975 AND 1985
),
TotalReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ReturnDetails AS (
    SELECT 
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        CASE 
            WHEN sr.sr_return_amt > 100 THEN 'High Value'
            ELSE 'Low Value'
        END AS return_type
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales)
)
SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.ws_order_number,
    rs.ws_net_profit,
    COALESCE(tr.total_returns, 0) AS returns_count,
    rd.return_type,
    COUNT(rd.sr_return_amt) * AVG(rd.sr_return_amt) AS return_statistics
FROM 
    RankedSales rs
LEFT JOIN 
    TotalReturns tr ON rs.c_customer_sk = tr.sr_customer_sk
LEFT JOIN 
    ReturnDetails rd ON rs.c_customer_sk = rd.sr_customer_sk
WHERE 
    (
        (rs.rnk = 1 AND rd.sr_return_amt IS NOT NULL)
        OR (rs.rnk > 1 AND rd.return_type = 'High Value')
    )
GROUP BY 
    rs.c_first_name,
    rs.c_last_name,
    rs.ws_order_number,
    rs.ws_net_profit,
    tr.total_returns,
    rd.return_type
HAVING 
    SUM(rd.sr_return_amt) IS NULL 
    OR SUM(rd.sr_return_amt) > 50.00
ORDER BY 
    rs.ws_net_profit DESC,
    returns_count ASC
LIMIT 100;
