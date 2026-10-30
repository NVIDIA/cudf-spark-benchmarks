WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_order_number
),
high_value_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender
    HAVING
        SUM(ws_net_paid) > 1000  
),
inventory_status AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
)
SELECT
    hs.c_first_name,
    hs.c_last_name,
    hs.order_count,
    hs.total_spent,
    COALESCE(ir.total_quantity_on_hand, 0) AS quantity_available,
    rs.total_quantity AS quantity_sold,
    rs.total_net_paid AS revenue_generated
FROM
    high_value_customers hs
LEFT JOIN
    ranked_sales rs ON hs.order_count = rs.sales_rank
LEFT JOIN
    inventory_status ir ON rs.ws_item_sk = ir.inv_item_sk
WHERE
    (hs.order_count > 5 OR hs.total_spent > 500)  
ORDER BY
    hs.total_spent DESC
LIMIT 50;