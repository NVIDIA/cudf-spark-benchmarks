
WITH  sales_totals AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_ship_date_sk BETWEEN 2452021 AND 2452084
    GROUP BY
        ws_item_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price,
        COALESCE(SUM(ss_ext_sales_price), 0) AS store_sales
    FROM 
        item i
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price
), 
ranked_items AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY i_current_price ORDER BY total_sales DESC) AS price_rank
    FROM 
        sales_totals
    JOIN 
        item_details ON sales_totals.ws_item_sk = item_details.i_item_sk
)
SELECT 
    r.i_item_desc,
    r.total_sales,
    r.total_orders,
    r.sales_rank,
    r.price_rank,
    CASE WHEN r.price_rank = 1 THEN 'Top Price Item'
         ELSE 'Regular Price Item' END AS price_category,
    NULLIF(i.i_current_price, 0) AS adjusted_price
FROM 
    ranked_items r
JOIN 
    item i ON r.ws_item_sk = i.i_item_sk
WHERE 
    r.sales_rank <= 10 AND r.price_rank <= 5
ORDER BY 
    r.sales_rank, r.price_rank;
