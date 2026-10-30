
WITH PriceTrends AS (
    SELECT 
        i.i_item_sk,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopItems AS (
    SELECT 
        i.i_item_id,
        pt.avg_sales_price,
        pt.total_quantity_sold,
        ROW_NUMBER() OVER (ORDER BY pt.total_quantity_sold DESC) AS rnk
    FROM 
        PriceTrends pt
    JOIN 
        item i ON pt.i_item_sk = i.i_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    ti.i_item_id,
    ti.avg_sales_price,
    ti.total_quantity_sold,
    CASE 
        WHEN cs.total_orders > 0 
        THEN cs.total_spent / cs.total_orders 
        ELSE 0 
    END AS avg_spent_per_order,
    COALESCE(
        (SELECT 
            MAX(sr_return_quantity) 
         FROM 
            store_returns sr 
         WHERE 
            sr.sr_customer_sk = cs.c_customer_sk), 0) AS max_returned_quantity
FROM 
    CustomerStats cs
JOIN 
    TopItems ti ON cs.total_orders > 0
WHERE 
    cs.cd_gender = 'F' 
    AND ti.rnk <= 5
ORDER BY 
    cs.total_spent DESC, ti.total_quantity_sold DESC;
