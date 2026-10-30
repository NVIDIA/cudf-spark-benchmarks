
WITH SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeGrouping AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_range,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
TopCustomers AS (
    SELECT 
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.total_spent,
        RANK() OVER (ORDER BY ss.total_spent DESC) AS spending_rank
    FROM 
        SalesSummary ss
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    ig.income_range,
    ig.customer_count,
    CASE 
        WHEN tc.total_spent > 1000 THEN 'High Value'
        WHEN tc.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    TopCustomers tc
LEFT JOIN 
    IncomeGrouping ig ON tc.c_customer_sk = ig.hd_demo_sk
WHERE 
    tc.spending_rank <= 10;
