
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
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
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458970 AND 2459335 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
), month_summary AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ss.total_sales) AS monthly_sales, 
        SUM(ss.total_quantity) AS monthly_quantity,
        COUNT(DISTINCT ss.c_customer_id) AS unique_customers
    FROM 
        sales_summary ss
    JOIN 
        date_dim d ON d.d_date_sk BETWEEN 2458970 AND 2459335
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    ms.d_year,
    ms.d_month_seq,
    ms.monthly_sales,
    ms.monthly_quantity,
    ms.unique_customers,
    AVG(ms.monthly_sales) OVER (PARTITION BY ms.d_year ORDER BY ms.d_month_seq) AS avg_monthly_sales
FROM 
    month_summary ms
ORDER BY 
    ms.d_year, ms.d_month_seq;
