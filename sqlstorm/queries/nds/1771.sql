
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
TopSpenders AS (
    SELECT 
        c.c_customer_id,
        cp.total_spent,
        cp.total_orders,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        CustomerPurchases cp
    JOIN 
        customer c ON cp.c_customer_id = c.c_customer_id
),
Surveys AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(hd.hd_vehicle_count) AS average_vehicle_count,
        COUNT(DISTINCT hd.hd_demo_sk) AS unique_households
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ts.c_customer_id,
    ts.total_spent,
    ts.total_orders,
    sa.average_vehicle_count,
    sa.unique_households
FROM 
    TopSpenders ts
LEFT JOIN 
    Surveys sa ON ts.rank <= 10
WHERE 
    ts.total_orders > 5
ORDER BY 
    ts.total_spent DESC
LIMIT 10;
