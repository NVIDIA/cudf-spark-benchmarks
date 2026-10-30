
WITH  sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        MIN(ws_sales_price) AS min_sales_price,
        MAX(ws_sales_price) AS max_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 10
),
inventory_cte AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
customer_rank AS (
    SELECT 
        c_customer_sk,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
        ROW_NUMBER() OVER (ORDER BY SUM(cd_purchase_estimate) DESC) AS customer_rank
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_customer_sk
)
SELECT 
    s.ws_item_sk,
    i.total_inventory,
    s.total_sold_quantity,
    s.min_sales_price,
    s.max_sales_price,
    cr.male_customers,
    cr.female_customers
FROM 
    sales_cte s
LEFT JOIN 
    inventory_cte i ON s.ws_item_sk = i.inv_item_sk
LEFT JOIN 
    customer_rank cr ON cr.customer_rank <= 10
WHERE 
    s.rank < 5
ORDER BY 
    s.total_sold_quantity DESC, s.max_sales_price ASC
LIMIT 100;
