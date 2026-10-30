WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459000 AND 2459006 
    GROUP BY 
        c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales) 
)
SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    high_value_customers hvc
JOIN 
    income_band ib ON hvc.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    hvc.total_sales DESC
LIMIT 10;