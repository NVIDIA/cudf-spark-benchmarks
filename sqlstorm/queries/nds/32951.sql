
WITH  sales_hierarchy AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM store s
    JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY s.s_store_sk, s.s_store_name
), 
demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_net_profit ELSE 0 END) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM customer_demographics cd
    LEFT JOIN catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT
    sh.s_store_name,
    ds.cd_gender,
    ds.orders_count,
    ds.total_profit,
    ds.avg_sales_price
FROM sales_hierarchy sh
JOIN demographics_summary ds ON sh.total_net_profit > ds.total_profit
WHERE ds.orders_count > 5 
  AND ds.cd_gender IS NOT NULL
ORDER BY sh.total_net_profit DESC, ds.total_profit ASC
LIMIT 10;
