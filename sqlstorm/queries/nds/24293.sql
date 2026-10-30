
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
discounted_sales AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_quantity, 
        ss.total_sales,
        COALESCE(cs.cs_ext_discount_amt, 0) AS total_discount
    FROM 
        sales_summary ss
    LEFT JOIN 
        catalog_sales cs ON ss.ws_item_sk = cs.cs_item_sk AND cs.cs_sold_date_sk = ss.ws_item_sk
),
final_summary AS (
    SELECT 
        d.ws_item_sk,
        d.total_quantity,
        d.total_sales,
        d.total_discount,
        (d.total_sales - d.total_discount) AS net_sales,
        CASE 
            WHEN d.total_sales IS NULL THEN 'Unknown'
            WHEN d.total_sales = 0 THEN 'Zero Sales'
            ELSE 'Active Sales'
        END AS sales_status,
        ROW_NUMBER() OVER (PARTITION BY d.ws_item_sk ORDER BY (d.total_sales - d.total_discount) DESC) AS row_num
    FROM 
        discounted_sales d
)
SELECT 
    fs.ws_item_sk,
    fs.total_quantity,
    fs.total_sales,
    fs.total_discount,
    fs.net_sales,
    fs.sales_status
FROM 
    final_summary fs
WHERE 
    (fs.net_sales > 0 OR fs.sales_status = 'Zero Sales')
    AND fs.row_num <= 10
UNION ALL
SELECT 
    NULL AS ws_item_sk,
    NULL AS total_quantity,
    NULL AS total_sales,
    NULL AS total_discount,
    NULL AS net_sales,
    'End of Results' AS sales_status
ORDER BY 
    ws_item_sk DESC NULLS LAST;
