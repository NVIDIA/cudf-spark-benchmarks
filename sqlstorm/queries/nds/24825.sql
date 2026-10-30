
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CASE
            WHEN COUNT(DISTINCT ws.ws_order_number) IS NULL THEN 'No Orders'
            ELSE 'Orders Present'
        END AS order_status
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
income_distribution AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS income_count,
        COALESCE(AVG(cs.total_spent), 0) AS avg_income_spent
    FROM 
        household_demographics h
    LEFT JOIN 
        customer c ON h.hd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY 
        h.hd_income_band_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent
    FROM 
        customer_sales cs
    WHERE 
        cs.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                customer_sales
        )
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(i.income_count, 0) AS customer_income_count,
    COALESCE(i.avg_income_spent, 0) AS avg_income_internet_spent,
    CASE 
        WHEN hv.total_spent IS NOT NULL THEN 'High Value'
        ELSE 'Regular'
    END AS customer_status
FROM 
    customer c
LEFT JOIN 
    income_distribution i ON c.c_current_cdemo_sk = i.hd_income_band_sk
LEFT JOIN 
    high_value_customers hv ON c.c_customer_sk = hv.c_customer_sk
WHERE 
    (i.income_count IS NOT NULL OR hv.total_spent IS NOT NULL)
ORDER BY 
    c.c_last_name ASC, 
    c.c_first_name ASC
LIMIT 100;
