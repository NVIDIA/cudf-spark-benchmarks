WITH  Sales_Data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 0
),
Top_Items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        d.d_date AS sale_date,
        COALESCE(r.r_reason_desc, 'No Reason') AS return_reason,
        LEAD(sd.total_sales) OVER (ORDER BY sd.total_sales DESC) AS next_sales
    FROM 
        Sales_Data sd
    LEFT JOIN date_dim d ON d.d_date_sk = (SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_date = cast('2002-10-01' as date) - INTERVAL '1 day')
    LEFT JOIN store_returns sr ON sr.sr_item_sk = sd.ws_item_sk
    LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
),
Final_Report AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        ti.sale_date,
        ti.return_reason,
        CASE 
            WHEN ti.total_sales IS NULL THEN 'No Sales'
            WHEN ti.total_sales < COALESCE(ti.next_sales, 0) THEN 'Declining Sales'
            ELSE 'Consistent Sales'
        END AS sales_trend
    FROM 
        Top_Items ti
)

SELECT 
    itm.i_item_id,
    itm.i_product_name,
    fr.total_quantity,
    fr.total_sales,
    fr.sale_date,
    fr.return_reason,
    fr.sales_trend
FROM 
    item itm
INNER JOIN Final_Report fr ON itm.i_item_sk = fr.ws_item_sk
WHERE 
    fr.total_sales > 1000
ORDER BY 
    fr.total_sales DESC;