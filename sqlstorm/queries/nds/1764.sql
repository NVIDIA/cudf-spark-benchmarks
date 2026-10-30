
WITH top_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING 
        SUM(ws.ws_net_paid) IS NOT NULL
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
sales_with_rank AS (
    SELECT 
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        RANK() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY SUM(ss.ss_quantity) DESC) AS sales_rank
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk, ss.ss_sold_date_sk
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name,
    tc.cd_gender,
    sr.total_quantity_sold,
    inv.total_inventory
FROM 
    top_customers tc
JOIN 
    sales_with_rank sr ON tc.c_customer_sk = (
        SELECT ws.ws_bill_customer_sk 
        FROM web_sales ws 
        WHERE ws.ws_item_sk IN (
            SELECT i.i_item_sk FROM item i 
            WHERE i.i_brand = 'BrandA'
        )
        LIMIT 1
    )
LEFT JOIN 
    inventory_status inv ON sr.ss_item_sk = inv.inv_item_sk
WHERE 
    tc.total_spent > (SELECT AVG(total_spent) FROM top_customers)
ORDER BY 
    tc.total_spent DESC,
    sr.sales_rank ASC;
