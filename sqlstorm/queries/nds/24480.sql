
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_ship_date_sk) AS latest_ship_date
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 AND dd.d_moy IN (1, 2, 3)
    GROUP BY ws.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SUM(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_store_sales,
        COALESCE(SUM(CASE WHEN cs.cs_sold_date_sk IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_catalog_sales
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_current_price
),
detailed_sales AS (
    SELECT 
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        ss.total_quantity,
        ss.total_sales,
        ss.total_discount,
        ss.total_net_profit,
        id.total_store_sales,
        id.total_catalog_sales,
        RANK() OVER (PARTITION BY id.i_item_sk ORDER BY ss.total_net_profit DESC) AS net_profit_rank
    FROM item_details id
    LEFT JOIN sales_summary ss ON id.i_item_sk = ss.ws_item_sk
)
SELECT 
    ds.i_item_sk,
    ds.i_item_desc,
    ds.i_current_price,
    ds.total_quantity,
    ds.total_sales,
    ds.total_discount,
    ds.total_net_profit,
    ds.total_store_sales,
    ds.total_catalog_sales,
    CASE 
        WHEN ds.net_profit_rank = 1 THEN 'Top Performer'
        WHEN ds.net_profit_rank IS NULL THEN 'No Sales'
        ELSE 'Standard'
    END AS performance_category
FROM detailed_sales ds
WHERE (ds.total_net_profit > 100 OR ds.total_store_sales > 100)
  AND (ds.total_catalog_sales IS NULL OR ds.total_catalog_sales < 50)
  AND (ds.total_quantity IS NOT NULL AND ds.total_sales IS NOT NULL)
ORDER BY ds.total_net_profit DESC, ds.i_item_sk
LIMIT 100;
