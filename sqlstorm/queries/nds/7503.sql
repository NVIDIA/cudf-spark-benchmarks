
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_spent_per_order
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerSales
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    tc.avg_spent_per_order,
    cd.cd_gender,
    cd.cd_marital_status,
    hd.hd_income_band_sk
FROM 
    TopCustomers tc
JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
JOIN 
    household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
