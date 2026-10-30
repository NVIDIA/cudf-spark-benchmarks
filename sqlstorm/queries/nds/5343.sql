
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
), time_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS monthly_sales
    FROM 
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, 
        d.d_month_seq
), average_spending AS (
    SELECT 
        cs.c_customer_sk,
        AVG(cs.total_spent) AS avg_spent
    FROM 
        customer_summary cs
    GROUP BY 
        cs.c_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    ts.d_year,
    ts.d_month_seq,
    ts.monthly_sales,
    asp.avg_spent
FROM 
    customer_summary cs
    JOIN time_summary ts ON cs.total_orders > 0
    JOIN average_spending asp ON cs.c_customer_sk = asp.c_customer_sk
WHERE 
    ts.monthly_sales > 5000
ORDER BY 
    cs.total_spent DESC, 
    ts.d_year DESC, 
    ts.d_month_seq DESC
LIMIT 50;
