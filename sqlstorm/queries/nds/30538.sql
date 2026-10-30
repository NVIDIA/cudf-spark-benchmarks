
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 10

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY cs_item_sk
    HAVING SUM(cs_quantity) > 10
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) as sales_rank
    FROM sales_summary
)
SELECT 
    sm.sm_type,
    r.r_reason_desc,
    ss.ws_item_sk,
    ss.total_quantity,
    ss.total_sales,
    ss.sales_rank
FROM ranked_sales ss
LEFT JOIN item i ON ss.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON i.i_item_sk = sm.sm_ship_mode_sk
JOIN reason r ON r.r_reason_sk = ss.ws_item_sk
WHERE ss.sales_rank <= 10
  AND (i.i_current_price < 50 OR i.i_current_price IS NULL)
ORDER BY ss.total_sales DESC, sm.sm_carrier;
