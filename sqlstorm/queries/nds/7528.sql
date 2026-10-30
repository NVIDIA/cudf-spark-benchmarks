
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS average_profit,
        cd_gender, 
        cd_marital_status,
        ib_income_band_sk,
        d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws_bill_customer_sk, cd_gender, cd_marital_status, ib_income_band_sk, d_year
),
top_customers AS (
    SELECT 
        customer_id, 
        total_sales, 
        total_orders, 
        average_profit,
        ROW_NUMBER() OVER (PARTITION BY ib_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    t.customer_id, 
    t.total_sales, 
    t.total_orders, 
    t.average_profit, 
    s.ib_income_band_sk
FROM 
    top_customers t
JOIN 
    sales_summary s ON t.customer_id = s.customer_id
WHERE 
    t.sales_rank <= 10
ORDER BY 
    s.ib_income_band_sk, t.total_sales DESC;
