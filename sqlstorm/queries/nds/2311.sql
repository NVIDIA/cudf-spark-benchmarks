
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_net_profit,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) as profit_rank
    FROM catalog_sales
), 
ReturningCustomers AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS num_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    HAVING SUM(wr_return_amt) > 100
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
    AVG(rs.cs_net_profit) AS avg_net_profit,
    rs.cs_quantity,
    rc.total_return_amt,
    COALESCE(rc.num_returns, 0) as num_returns
FROM customer AS c
JOIN customer_address AS a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN RankedSales AS rs ON ws.ws_item_sk = rs.cs_item_sk AND rs.profit_rank = 1
LEFT JOIN ReturningCustomers AS rc ON c.c_customer_sk = rc.wr_returning_customer_sk
WHERE a.ca_city IS NOT NULL
GROUP BY 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    rs.cs_quantity,
    rc.total_return_amt,
    rc.num_returns
ORDER BY total_sales DESC
LIMIT 50;
