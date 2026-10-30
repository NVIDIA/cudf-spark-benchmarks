
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
      AND (i.i_category_id IN (SELECT DISTINCT i_category_id FROM item WHERE i_brand_id IS NULL) 
           OR i.i_brand_id IS NULL)
      AND i.i_item_desc NOT LIKE '%expired%'
    GROUP BY ws.ws_order_number, ws.ws_item_sk
),
returns_data AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity IS NOT NULL
    GROUP BY cr.cr_item_sk
),
final_result AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        (sd.total_sales - COALESCE(rd.total_return_amount, 0)) AS net_sales,
        CASE 
            WHEN COALESCE(rd.total_returned_quantity, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM sales_data sd
    LEFT JOIN returns_data rd ON sd.ws_item_sk = rd.cr_item_sk
    WHERE sd.sales_rank = 1
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_sales,
    fr.total_returned_quantity,
    fr.total_return_amount,
    fr.net_sales,
    fr.return_status
FROM final_result fr
WHERE fr.net_sales > 0
AND fr.net_sales < 1000
ORDER BY fr.net_sales DESC
LIMIT 50;
