WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459357 AND 2459686  
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_quantity,
        total_sales,
        order_count,
        avg_order_value,
        cd_gender,
        cd_marital_status,
        ib_income_band_sk,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity,
    tc.total_sales,
    tc.order_count,
    tc.avg_order_value,
    tc.cd_gender,
    tc.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    top_customers tc
JOIN 
    income_band ib ON tc.ib_income_band_sk = ib.ib_income_band_sk
WHERE 
    sales_rank <= 100  
ORDER BY 
    total_sales DESC;