
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450834 AND 2454069
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS sales_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2450834 AND 2454069
    GROUP BY 
        cs_item_sk
),
ranked_sales AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        COALESCE(ss.total_quantity, 0) AS web_sales_quantity,
        COALESCE(cs.total_quantity, 0) AS catalog_sales_quantity,
        COALESCE(ss.total_sales, 0) AS web_sales,
        COALESCE(cs.total_sales, 0) AS catalog_sales,
        COALESCE(ss.total_sales, 0) + COALESCE(cs.total_sales, 0) AS total_sales_combined,
        CASE
            WHEN COALESCE(ss.total_sales, 0) + COALESCE(cs.total_sales, 0) > 10000 THEN 'High Sales'
            WHEN COALESCE(ss.total_sales, 0) + COALESCE(cs.total_sales, 0) BETWEEN 5000 AND 10000 THEN 'Medium Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM 
        item
    LEFT JOIN 
        (SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_paid) AS total_sales
         FROM web_sales
         GROUP BY ws_item_sk) ss ON item.i_item_sk = ss.ws_item_sk
    LEFT JOIN 
        (SELECT cs_item_sk, SUM(cs_quantity) AS total_quantity, SUM(cs_net_paid) AS total_sales
         FROM catalog_sales
         GROUP BY cs_item_sk) cs ON item.i_item_sk = cs.cs_item_sk
)
SELECT 
    r.i_item_sk,
    r.i_product_name,
    r.web_sales_quantity,
    r.catalog_sales_quantity,
    r.web_sales,
    r.catalog_sales,
    r.total_sales_combined,
    r.sales_category,
    RANK() OVER (ORDER BY r.total_sales_combined DESC) AS sales_global_rank
FROM 
    ranked_sales r
WHERE 
    r.total_sales_combined > 0
ORDER BY 
    r.total_sales_combined DESC
LIMIT 100;
