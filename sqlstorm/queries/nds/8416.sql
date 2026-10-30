
WITH customer_return_stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_quantity ELSE 0 END) AS total_returns,
        SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_amt ELSE 0 END) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        COALESCE(AVG(CASE WHEN sr_return_quantity > 0 THEN sr_return_amt_inc_tax END), 0) AS avg_return_value
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
warehouse_inventory AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_purchases
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cs.cs_item_sk
    ORDER BY 
        total_purchases DESC
    LIMIT 10
)
SELECT
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    cr.total_returns,
    cr.total_return_amount,
    cr.return_count,
    cr.avg_return_value,
    wi.w_warehouse_id AS warehouse_id,
    wi.total_inventory,
    tc.total_purchases
FROM 
    customer_return_stats cr
JOIN 
    warehouse_inventory wi ON cr.total_returns > 0
JOIN 
    top_customers tc ON cr.c_customer_id = tc.c_customer_id
WHERE 
    cr.total_return_amount > 1000
ORDER BY 
    cr.total_return_amount DESC, tc.total_purchases DESC
LIMIT 50;
