WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 2450000  
), 
item_summary AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(sd.ws_sales_price) AS total_sales,
        COUNT(DISTINCT sd.ws_order_number) AS order_count,
        COALESCE(AVG(sd.ws_sales_price), 0) AS avg_price
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.rn = 1
    GROUP BY 
        i.i_item_id, 
        i.i_product_name
),
top_items AS (
    SELECT 
        i_sum.i_item_id,
        i_sum.i_product_name,
        i_sum.total_sales,
        i_sum.order_count,
        RANK() OVER (ORDER BY i_sum.total_sales DESC) AS sales_rank
    FROM 
        item_summary i_sum
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.total_sales,
    ti.order_count,
    CASE 
        WHEN ti.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS sales_category
FROM 
    top_items ti
WHERE 
    ti.total_sales IS NOT NULL
ORDER BY 
    ti.total_sales DESC;