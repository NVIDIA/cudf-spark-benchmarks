
WITH CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.order_count,
        cs.average_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSpending cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_spent > 5000
),
TopProducts AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold
    FROM 
        web_sales ws
    JOIN 
        HighSpenders hs ON ws.ws_bill_customer_sk = hs.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_sold DESC
    LIMIT 10
)
SELECT 
    p.i_item_id,
    p.i_item_desc,
    tp.total_sold,
    hs.average_order_value,
    hs.cd_gender,
    hs.cd_marital_status,
    hs.cd_education_status
FROM 
    item p
JOIN 
    TopProducts tp ON p.i_item_sk = tp.ws_item_sk
JOIN 
    HighSpenders hs ON tp.total_sold > 0
ORDER BY 
    tp.total_sold DESC;
