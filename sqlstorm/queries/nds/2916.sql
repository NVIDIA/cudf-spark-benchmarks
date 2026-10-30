
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeEstimates AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_band
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_spent, 0) AS total_spent,
        COALESCE(cs.order_count, 0) AS order_count,
        ie.income_band
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        IncomeEstimates ie ON cs.c_customer_sk = ie.hd_demo_sk
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_spent,
    s.order_count,
    s.income_band,
    RANK() OVER (PARTITION BY s.income_band ORDER BY s.total_spent DESC) AS income_rank,
    CASE 
        WHEN s.total_spent IS NULL THEN 'No Purchases'
        WHEN s.total_spent < 100 THEN 'Low Value Customer'
        WHEN s.total_spent BETWEEN 100 AND 500 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_category
FROM 
    SalesSummary s
WHERE 
    (s.total_spent IS NOT NULL AND s.total_spent > 0) OR s.income_band IS NOT NULL
ORDER BY 
    s.income_band, total_spent DESC;
