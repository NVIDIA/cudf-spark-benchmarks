
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),

top_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)

SELECT 
    t.c_customer_id,
    t.total_sales,
    t.order_count,
    t.last_purchase_date,
    t.cd_gender,
    t.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    top_customers t
JOIN 
    income_band ib ON t.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.hd_income_band_sk, t.total_sales DESC;
