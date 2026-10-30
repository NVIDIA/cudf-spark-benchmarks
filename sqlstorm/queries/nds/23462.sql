
WITH RecursiveSales AS (
    SELECT 
        cs_order_number,
        cs_ship_mode_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
      AND cs_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY cs_order_number, cs_ship_mode_sk
    HAVING SUM(cs_net_profit) > (SELECT AVG(cs_net_profit) FROM catalog_sales WHERE cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022))
), 
RankedSales AS (
    SELECT 
        cs_order_number,
        cs_ship_mode_sk,
        total_quantity,
        total_profit,
        RANK() OVER (PARTITION BY cs_ship_mode_sk ORDER BY total_profit DESC) AS rank_per_mode,
        ROW_NUMBER() OVER (PARTITION BY cs_ship_mode_sk, total_quantity ORDER BY total_profit DESC) AS row_num
    FROM RecursiveSales
), 
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
), 
ProfitMargins AS (
    SELECT 
        s.s_store_id,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(ss_sales_price) AS store_sales,
        CASE WHEN SUM(ss_sales_price) > 0 THEN SUM(ss_net_profit) / SUM(ss_sales_price) ELSE NULL END AS profit_margin
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_id
)
SELECT 
    cs.c_customer_id,
    SUM(ps.store_net_profit) AS total_store_net_profit,
    AVG(ps.profit_margin) AS avg_profit_margin,
    MAX(rs.total_profit) AS highest_order_profit
FROM CustomerSales cs
JOIN ProfitMargins ps ON cs.total_orders > 0
LEFT JOIN RankedSales rs ON rs.rank_per_mode = 1
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
GROUP BY cs.c_customer_id
HAVING COUNT(DISTINCT cs.total_orders) > 1
   AND (AVG(ps.profit_margin) IS NULL OR AVG(ps.profit_margin) > 0.10)
ORDER BY total_store_net_profit DESC
LIMIT 100;
