
WITH SalesData AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_order_value,
        MAX(ws_sales_price) AS max_order_value,
        MIN(ws_sales_price) AS min_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk
),
Demographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        ib_income_band_sk,
        hd_buy_potential
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    d.ib_income_band_sk,
    COUNT(s.total_orders) AS customer_count,
    SUM(s.total_sales) AS total_revenue,
    AVG(s.avg_order_value) AS average_order_value,
    MAX(s.max_order_value) AS highest_order_value,
    MIN(s.min_order_value) AS lowest_order_value
FROM 
    SalesData s
JOIN 
    Demographics d ON s.cd_demo_sk = d.cd_demo_sk
WHERE 
    s.total_sales > 1000
GROUP BY 
    d.cd_gender, d.cd_marital_status, d.ib_income_band_sk
ORDER BY 
    total_revenue DESC;
