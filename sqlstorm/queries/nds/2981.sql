
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_purchase,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),

highest_spenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_purchase,
        RANK() OVER (ORDER BY cs.total_purchase DESC) AS purchase_rank
    FROM 
        customer_sales cs
    JOIN 
        customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
),

inventory_check AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        i.i_item_sk, i.i_product_name
)

SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.total_purchase,
    hs.purchase_rank,
    inv.i_product_name,
    inv.total_inventory
FROM 
    highest_spenders hs
LEFT JOIN 
    inventory_check inv ON hs.purchase_rank <= 10
WHERE 
    inv.total_inventory IS NOT NULL
ORDER BY 
    hs.purchase_rank;
