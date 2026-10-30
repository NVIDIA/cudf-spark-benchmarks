
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
StoreData AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid_inc_tax) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
CombinedSales AS (
    SELECT 
        sd.ws_item_sk,
        COALESCE(sd.total_quantity, 0) AS web_quantity,
        COALESCE(sd.total_sales, 0) AS web_sales,
        COALESCE(st.total_quantity, 0) AS store_quantity,
        COALESCE(st.total_sales, 0) AS store_sales,
        (COALESCE(sd.total_sales, 0) + COALESCE(st.total_sales, 0)) AS overall_sales
    FROM 
        SalesData sd
    FULL OUTER JOIN 
        StoreData st ON sd.ws_item_sk = st.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    cs.web_quantity,
    cs.web_sales,
    cs.store_quantity,
    cs.store_sales,
    cs.overall_sales,
    CASE 
        WHEN cs.overall_sales > 1000 THEN 'High Sales'
        WHEN cs.overall_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    CombinedSales cs
JOIN 
    item i ON cs.ws_item_sk = i.i_item_sk
WHERE 
    cs.overall_sales > 0
ORDER BY 
    cs.overall_sales DESC
LIMIT 10;
