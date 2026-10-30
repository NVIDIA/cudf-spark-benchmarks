
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_moy IN (1, 2, 3)
    )
), 
RecentStores AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk 
        AND ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_month_seq = 3)
    GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_state
), 
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS return_amount
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    MAX(ca.ca_city) AS customer_city,
    MAX(ca.ca_state) AS customer_state,
    SUM(rs.ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT CASE WHEN rr.total_returns > 0 THEN rr.c_customer_sk END) AS customers_with_returns,
    AVG(rs.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ss.s_store_sk) AS unique_stores
FROM customer cs
JOIN customer_address ca ON cs.c_current_addr_sk = ca.ca_address_sk
JOIN RankedSales rs ON cs.c_customer_sk = rs.ws_order_number
JOIN RecentStores ss ON ss.total_sales > 1
LEFT JOIN CustomerReturns rr ON cs.c_customer_sk = rr.c_customer_sk
WHERE 
    cs.c_birth_year BETWEEN 1970 AND 1990
    AND (rs.profit_rank <= 5 OR rr.total_returns > 0)
GROUP BY cs.c_customer_sk, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT rs.ws_order_number) > 10
    AND SUM(rs.ws_quantity) NOT BETWEEN 0 AND 1000
    AND (MAX(rr.return_amount) IS NULL OR MAX(rr.return_amount) > 50)
ORDER BY avg_net_profit DESC
LIMIT 100;
