
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
CustomerRanks AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS rank_by_spent,
        RANK() OVER (PARTITION BY cd_marital_status ORDER BY total_orders DESC) AS rank_by_orders
    FROM 
        CustomerPurchases
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.total_spent,
    cr.total_orders,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.rank_by_spent,
    cr.rank_by_orders
FROM 
    CustomerRanks cr
WHERE 
    cr.rank_by_spent <= 10 AND cr.rank_by_orders <= 10
ORDER BY 
    cr.cd_gender, cr.total_spent DESC, cr.total_orders DESC;
