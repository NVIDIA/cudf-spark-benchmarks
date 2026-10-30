
WITH  sales_data AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS rn
    FROM
        store_sales ss
    WHERE
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ss.ss_item_sk
),
top_sales AS (
    SELECT
        sd.ss_item_sk,
        sd.total_sales,
        sd.total_transactions,
        sd.total_quantity 
    FROM
        sales_data sd
    WHERE
        sd.rn <= 10
),
sales_analysis AS (
    SELECT
        ts.ss_item_sk,
        ts.total_sales,
        ts.total_transactions,
        ts.total_quantity,
        COALESCE((SELECT AVG(total_sales) FROM top_sales WHERE total_transactions > 5), 0) AS avg_sales,
        CASE 
            WHEN ts.total_sales > COALESCE((SELECT AVG(total_sales) FROM top_sales), 0) THEN 'above_average'
            WHEN ts.total_sales = COALESCE((SELECT AVG(total_sales) FROM top_sales), 0) THEN 'average'
            ELSE 'below_average'
        END AS performance_category
    FROM
        top_sales ts
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    sa.total_sales,
    sa.total_transactions,
    sa.avg_sales,
    sa.performance_category
FROM
    sales_analysis sa
JOIN
    item i ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN
    (SELECT 
         ss.ss_item_sk, 
         COUNT(DISTINCT cs.cs_order_number) AS cp_orders 
     FROM 
         catalog_sales cs 
     LEFT JOIN 
         store_sales ss ON cs.cs_item_sk = ss.ss_item_sk 
     GROUP BY 
         ss.ss_item_sk 
     HAVING 
         COUNT(ss.ss_ticket_number) > 0) AS cps ON sa.ss_item_sk = cps.ss_item_sk
WHERE
    (sa.avg_sales IS NOT NULL OR cps.cp_orders IS NOT NULL)
ORDER BY
    sa.total_sales DESC, sa.performance_category ASC;
