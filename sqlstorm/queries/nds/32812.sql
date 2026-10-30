
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
combined_sales AS (
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS rank_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
store_sales_summary AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank_sales
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
)
SELECT 
    COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk, ss.ss_sold_date_sk) AS sold_date_sk,
    COALESCE(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk) AS item_sk,
    SUM(COALESCE(ws.total_quantity, 0) + COALESCE(cs.total_quantity, 0) + COALESCE(ss.total_quantity, 0)) AS total_quantity,
    SUM(COALESCE(ws.total_sales, 0) + COALESCE(cs.total_sales, 0) + COALESCE(ss.total_sales, 0)) AS total_sales
FROM 
    sales_summary ws
FULL OUTER JOIN 
    combined_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
FULL OUTER JOIN 
    store_sales_summary ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
WHERE 
    (ws.rank_sales < 10 OR cs.rank_sales < 10 OR ss.rank_sales < 10)
GROUP BY 
    COALESCE(ws.ws_sold_date_sk, cs.cs_sold_date_sk, ss.ss_sold_date_sk),
    COALESCE(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk)
ORDER BY 
    sold_date_sk, total_sales DESC
LIMIT 100;
