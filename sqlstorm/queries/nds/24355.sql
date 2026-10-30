
WITH  cte_customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sale_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
cte_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
cte_item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        id.ib_upper_bound AS income_upper,
        id.ib_lower_bound AS income_lower
    FROM item i
    JOIN income_band id ON i.i_brand_id = id.ib_income_band_sk
    WHERE i.i_current_price IS NOT NULL
),
cte_sales_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count,
        CASE 
            WHEN SUM(ws.ws_ext_sales_price) IS NULL THEN 'No Sales' 
            ELSE CASE 
                WHEN SUM(ws.ws_ext_sales_price) < 1000 THEN 'Low Sales'
                WHEN SUM(ws.ws_ext_sales_price) BETWEEN 1000 AND 5000 THEN 'Medium Sales'
                ELSE 'High Sales' 
            END 
        END AS sales_category
    FROM cte_customer_sales cs
    JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cs.c_customer_sk, cs.c_first_name, cs.c_last_name
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(i.total_stock, 0) AS available_stock,
    sa.total_web_sales,
    sa.order_count,
    sa.sales_category,
    CASE 
        WHEN sa.sales_category = 'High Sales' AND i.total_stock < 10 THEN 'Low Stock'
        ELSE 'Sufficient Stock'
    END AS stock_status
FROM cte_sales_analysis sa
JOIN cte_customer_sales c ON sa.c_customer_sk = c.c_customer_sk
LEFT JOIN cte_inventory i ON c.c_customer_sk = i.inv_item_sk
WHERE sa.total_web_sales IS NOT NULL
ORDER BY c.c_first_name, c.c_last_name;
