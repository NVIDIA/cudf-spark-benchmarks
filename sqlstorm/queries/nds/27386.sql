
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopSpenders AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.cd_gender,
        cp.cd_marital_status,
        cp.total_spent,
        cp.total_orders,
        DENSE_RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        CustomerPurchases cp
),
HighSpenders AS (
    SELECT 
        ts.c_customer_sk,
        ts.c_first_name,
        ts.c_last_name,
        ts.cd_gender,
        ts.cd_marital_status,
        ts.total_spent,
        ts.total_orders
    FROM 
        TopSpenders ts
    WHERE 
        ts.rank <= 10
)
SELECT 
    CONCAT(hs.c_first_name, ' ', hs.c_last_name) AS full_name,
    hs.cd_gender,
    hs.cd_marital_status,
    hs.total_spent,
    hs.total_orders
FROM 
    HighSpenders hs
ORDER BY 
    hs.total_spent DESC;
