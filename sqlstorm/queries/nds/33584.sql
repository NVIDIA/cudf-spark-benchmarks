
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sale_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        ws_item_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        SUM(ws.ws_sales_price) AS customer_total,
        COUNT(ws.ws_order_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_credit_rating
    HAVING 
        SUM(ws.ws_sales_price) > 10000
    ORDER BY 
        customer_total DESC
),
top_ship_modes AS (
    SELECT 
        sm.sm_ship_mode_id,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
    HAVING 
        SUM(ws.ws_ext_ship_cost) > 5000
),
null_handling AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN c.c_birth_country IS NULL THEN 'Unknown'
            ELSE c.c_birth_country
        END AS birth_country,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_birth_country
),
inventory_analysis AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = 1
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.purchase_count,
    hvc.customer_total,
    ns.birth_country,
    iv.total_quantity,
    iv.warehouse_count,
    ts.total_ship_cost
FROM 
    high_value_customers hvc
LEFT JOIN 
    null_handling ns ON hvc.c_customer_sk = ns.c_customer_sk
LEFT JOIN 
    inventory_analysis iv ON hvc.c_customer_sk = iv.inv_item_sk
JOIN 
    top_ship_modes ts ON ts.total_ship_cost = (
        SELECT 
            MAX(total_ship_cost) 
        FROM 
            top_ship_modes
    )
WHERE 
    hvc.customer_total > (SELECT AVG(customer_total) FROM high_value_customers)
ORDER BY 
    hvc.customer_total DESC
LIMIT 10;
