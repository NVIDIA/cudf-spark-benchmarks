
WITH  sales_recursive AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_ext_sales_price) > 1000
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(inventory.inv_quantity_on_hand, 0) AS stock_quantity,
        CASE 
            WHEN i.i_current_price > 100 THEN 'Premium'
            WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'Mid-range'
            ELSE 'Budget'
        END AS price_category
    FROM 
        item i
    LEFT JOIN 
        inventory ON i.i_item_sk = inventory.inv_item_sk
),
top_sales AS (
    SELECT 
        item_details.i_item_sk,
        item_details.i_item_desc,
        item_details.i_current_price,
        item_details.stock_quantity,
        sales_recursive.total_quantity,
        sales_recursive.total_sales_amount,
        item_details.price_category
    FROM 
        item_details
    JOIN 
        sales_recursive ON item_details.i_item_sk = sales_recursive.ws_item_sk
    WHERE 
        sales_recursive.sales_rank <= 5
)
SELECT 
    ts.i_item_sk,
    ts.i_item_desc,
    ts.i_current_price,
    ts.stock_quantity,
    ts.total_quantity,
    ts.total_sales_amount,
    ts.price_category,
    CASE 
        WHEN ts.stock_quantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
     FROM web_sales 
     WHERE ws_item_sk = ts.i_item_sk) AS unique_buyers,
    (SELECT COUNT(*)
     FROM store_sales 
     WHERE ss_item_sk = ts.i_item_sk 
       AND ss_sold_date_sk >= (SELECT MIN(d_date_sk) 
                                FROM date_dim 
                                WHERE d_year = 2023)) AS store_sales_count
FROM 
    top_sales ts
WHERE 
    ts.price_category = 'Premium' OR ts.total_sales_amount > 5000
ORDER BY 
    ts.total_sales_amount DESC;
