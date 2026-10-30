
WITH customer_engagement AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
income_distribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(ce.total_spent) AS avg_spent
    FROM 
        household_demographics h
    JOIN 
        customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        customer_engagement ce ON c.c_customer_sk = ce.c_customer_sk
    GROUP BY 
        h.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    id.customer_count,
    id.avg_spent
FROM 
    income_band ib
JOIN 
    income_distribution id ON ib.ib_income_band_sk = id.hd_income_band_sk
WHERE 
    id.customer_count > 0
ORDER BY 
    ib.ib_lower_bound;
