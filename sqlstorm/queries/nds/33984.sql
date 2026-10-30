
WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 100 AND 200
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid_inc_tax) AS total_sales
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk BETWEEN 100 AND 200
    GROUP BY 
        cs_item_sk
),
combined_sales AS (
    SELECT 
        item.i_item_sk,
        COALESCE(ws.total_quantity, 0) AS web_quantity,
        COALESCE(ws.total_sales, 0) AS web_sales,
        COALESCE(cs.total_quantity, 0) AS catalog_quantity,
        COALESCE(cs.total_sales, 0) AS catalog_sales
    FROM 
        item
    LEFT JOIN 
        (SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_paid) AS total_sales
         FROM web_sales GROUP BY ws_item_sk) ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        (SELECT cs_item_sk, SUM(cs_quantity) AS total_quantity, SUM(cs_net_paid) AS total_sales
         FROM catalog_sales GROUP BY cs_item_sk) cs ON item.i_item_sk = cs.cs_item_sk
),
final_results AS (
    SELECT 
        i_item_sk,
        web_quantity,
        catalog_quantity,
        web_sales,
        catalog_sales,
        (web_sales + catalog_sales) AS total_sales
    FROM 
        combined_sales
    WHERE 
        (web_sales + catalog_sales) > 0
),
ranked_results AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        final_results
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY sales_rank) AS rank,
    i_item_sk,
    web_quantity,
    catalog_quantity,
    web_sales,
    catalog_sales,
    total_sales
FROM 
    ranked_results
WHERE 
    sales_rank <= 10 OR (web_sales > 1000 AND catalog_sales IS NOT NULL);
