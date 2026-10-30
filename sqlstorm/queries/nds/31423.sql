
WITH  sales_data AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS total_orders
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        cs_item_sk
),
ranked_sales AS (
    SELECT 
        sd.cs_item_sk,
        sd.total_sales,
        sd.total_orders,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
),
top_items AS (
    SELECT 
        rs.cs_item_sk,
        rs.total_sales,
        rs.total_orders
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ti.total_sales, 0) AS total_sales,
    COALESCE(ti.total_orders, 0) AS total_orders,
    CASE 
        WHEN ti.total_sales > 0 THEN (ti.total_sales / NULLIF(SUM(ti.total_sales) OVER (), 0)) * 100
        ELSE 0 
    END AS sales_percentage,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) AS total_customers
FROM 
    item i
LEFT JOIN 
    top_items ti ON i.i_item_sk = ti.cs_item_sk
WHERE 
    i.i_current_price > 0
ORDER BY 
    total_sales DESC
LIMIT 5;
