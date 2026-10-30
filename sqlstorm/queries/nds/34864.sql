
WITH  CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        COUNT(ws.ws_order_number) > 0
),
IncomeDistribution AS (
    SELECT 
        hd.hd_demo_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN hd.hd_income_band_sk IS NOT NULL THEN 1 ELSE 0 END) AS valid_income
    FROM 
        household_demographics hd
    LEFT JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_demo_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    id.customer_count,
    id.valid_income,
    CASE 
        WHEN tc.spending_rank <= 10 THEN 'Top 10 Customers'
        ELSE 'Regular Customers'
    END AS customer_type
FROM 
    TopCustomers tc
LEFT JOIN 
    IncomeDistribution id ON tc.c_customer_sk = id.hd_demo_sk
WHERE 
    tc.total_spent IS NOT NULL 
    AND id.valid_income > 0
ORDER BY 
    tc.total_spent DESC
LIMIT 100;
