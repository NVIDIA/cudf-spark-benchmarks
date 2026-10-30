
WITH SalesData AS (
    SELECT 
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        cd_gender,
        ib_income_band_sk
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
    JOIN 
        income_band ON hd_income_band_sk = ib_income_band_sk
    WHERE 
        ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
    GROUP BY 
        cd_gender, ib_income_band_sk
)
SELECT 
    cd_gender,
    ib_income_band_sk,
    total_sales,
    total_orders,
    avg_order_value,
    RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
FROM 
    SalesData
ORDER BY 
    cd_gender, total_sales DESC;
