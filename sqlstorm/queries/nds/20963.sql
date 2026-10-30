
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL 
        AND ws.ws_net_paid_inc_tax > (SELECT AVG(ws2.ws_net_paid_inc_tax) FROM web_sales ws2 WHERE ws2.ws_item_sk = ws.ws_item_sk)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns 
    WHERE 
        wr_returned_date_sk BETWEEN 10000 AND 20000 
    GROUP BY 
        wr_returning_customer_sk
),
StorePerformance AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_quantity) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS unique_sales_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2021)
    GROUP BY 
        ss_store_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COALESCE(SUM(CASE WHEN rs.rn = 1 THEN rs.ws_net_profit END), 0) AS top_profit_web_sales,
    COALESCE(cr.total_returns, 0) AS total_customer_returns,
    COALESCE(sp.total_profit, 0) AS store_total_profit,
    COALESCE(sp.total_sales, 0) AS store_total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN 
    StorePerformance sp ON sp.ss_store_sk = (SELECT MIN(s_store_sk) FROM store WHERE s_division_id IS NULL)
WHERE 
    c.c_birth_year < (SELECT MAX(d_year) FROM date_dim)
    AND ca.ca_country IS NOT NULL
GROUP BY 
    c.c_customer_id, ca.ca_city, cr.total_returns, sp.total_profit, sp.total_sales
HAVING 
    SUM(COALESCE(rs.ws_net_profit, 0)) > 1000 
ORDER BY 
    top_profit_web_sales DESC, total_customer_returns DESC
LIMIT 10;
