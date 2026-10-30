
WITH RankedSales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_net_profit DESC) as rank
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
TotalSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(rs.cs_net_profit), 0) AS total_profit_from_catalog,
    COALESCE(SUM(ws.total_net_profit), 0) AS total_profit_from_web,
    CASE 
        WHEN SUM(rs.cs_net_profit) > SUM(ws.total_net_profit) THEN 'Catalog'
        ELSE 'Web'
    END AS preferred_channel
FROM customer c
LEFT JOIN RankedSales rs ON c.c_customer_sk = rs.cs_item_sk
LEFT JOIN TotalSales ws ON rs.cs_item_sk = ws.ws_item_sk
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
HAVING COALESCE(SUM(rs.cs_net_profit), 0) > 1000 OR COALESCE(SUM(ws.total_net_profit), 0) > 1000
ORDER BY preferred_channel, total_profit_from_web DESC, total_profit_from_catalog DESC;
