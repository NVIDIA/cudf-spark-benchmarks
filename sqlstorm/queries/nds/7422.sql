
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_moy BETWEEN 6 AND 8
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    COALESCE(ic.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(ic.ib_upper_bound, 0) AS income_upper_bound
FROM 
    TopCustomers tc
LEFT JOIN 
    household_demographics hd ON tc.c_customer_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ic ON hd.hd_income_band_sk = ic.ib_income_band_sk
WHERE 
    tc.spend_rank <= 10
ORDER BY 
    total_spent DESC;
