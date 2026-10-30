
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
BestCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.total_spent,
        rc.total_orders
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
)
SELECT 
    bc.c_customer_sk,
    bc.c_first_name,
    bc.c_last_name,
    bc.cd_gender,
    bc.total_spent,
    bc.total_orders,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders_this_year,
    SUM(ws.ws_ext_discount_amt) AS total_discounts
FROM 
    BestCustomers bc
LEFT JOIN 
    web_sales ws ON bc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    bc.c_customer_sk, bc.c_first_name, bc.c_last_name, bc.cd_gender, bc.total_spent, bc.total_orders, d.d_year
ORDER BY 
    bc.total_spent DESC;
