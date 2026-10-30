
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 365 FROM date_dim)
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(rs.ws_quantity) AS total_sales,
    COALESCE(tr.total_return_quantity, 0) AS total_returns,
    AVG(rs.ws_net_paid) AS avg_net_paid
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    TotalReturns tr ON rs.ws_item_sk = tr.sr_item_sk
WHERE 
    ca.ca_state = 'CA' AND
    c.c_birth_year BETWEEN 1970 AND 1990
GROUP BY 
    ca.ca_city,
    tr.total_return_quantity,
    rs.ws_quantity,
    rs.ws_net_paid
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    avg_net_paid DESC;
