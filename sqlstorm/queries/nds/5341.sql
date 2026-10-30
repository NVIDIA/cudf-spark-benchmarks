
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        ib_income_band_sk,
        COUNT(c_customer_id) AS customer_count,
        AVG(total_sales) AS avg_sales,
        SUM(total_sales) AS total_sales,
        AVG(order_count) AS avg_orders
    FROM 
        CustomerSales
    GROUP BY 
        cd_gender, cd_marital_status, ib_income_band_sk
)
SELECT 
    s.cd_gender,
    s.cd_marital_status,
    s.ib_income_band_sk,
    s.customer_count,
    s.avg_sales,
    s.total_sales,
    s.avg_orders,
    CASE 
        WHEN s.avg_sales > 500 THEN 'High Value'
        WHEN s.avg_sales BETWEEN 250 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    SalesSummary s
ORDER BY 
    total_sales DESC, customer_count DESC;
