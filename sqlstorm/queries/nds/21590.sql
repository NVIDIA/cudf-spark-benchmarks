WITH  CustomerRevenue AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_revenue,
        cr.order_count
    FROM 
        CustomerRevenue cr
    WHERE 
        cr.rn <= 10
),
DateRange AS (
    SELECT 
        d.d_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date >= DATE '2000-01-01' 
        AND d.d_date < DATE '2000-12-31'
    GROUP BY 
        d.d_date_sk
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_revenue, 0) AS total_revenue,
    COALESCE(cr.order_count, 0) AS order_count,
    CASE WHEN COALESCE(cr.total_revenue, 0) > 0 THEN 'Premium' ELSE 'Regular' END AS customer_type,
    ds.order_count AS total_orders_in_date_range,
    COALESCE(inv.total_quantity, 0) AS available_inventory
FROM 
    customer c
LEFT JOIN 
    TopCustomers cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN 
    DateRange ds ON ds.d_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date <= cast('2002-10-01' as date))
LEFT JOIN 
    InventoryStatus inv ON inv.inv_item_sk = (SELECT MIN(i.i_item_sk) FROM item i)
WHERE 
    c.c_birth_year IS NOT NULL 
    AND (c.c_first_name LIKE 'A%' OR c.c_last_name LIKE 'Z%')
ORDER BY 
    total_revenue DESC, c.c_last_name ASC;