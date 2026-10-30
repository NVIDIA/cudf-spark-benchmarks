
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_marital_status, cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_marital_status,
        rc.cd_gender,
        rc.total_spent
    FROM 
        RankedCustomers rc
    WHERE 
        rc.spend_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    COUNT(ws.ws_order_number) AS order_count,
    SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_first_name, tc.c_last_name, tc.total_spent
ORDER BY 
    total_spent DESC;
