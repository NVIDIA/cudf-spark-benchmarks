
WITH customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        SUM(NULLIF(ws.ws_quantity, 0)) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
sales_analysis AS (
    SELECT 
        cm.c_customer_sk,
        cm.total_quantity_sold,
        cm.total_sales,
        cm.order_count,
        ROW_NUMBER() OVER (PARTITION BY cm.hd_income_band_sk ORDER BY cm.total_sales DESC) AS rank_within_band
    FROM 
        customer_metrics cm
    WHERE 
        cm.total_sales > 1000
)
SELECT 
    sa.c_customer_sk,
    sa.total_quantity_sold,
    sa.total_sales,
    sa.order_count,
    sa.rank_within_band,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    sales_analysis sa
JOIN 
    customer_demographics cd ON sa.c_customer_sk = cd.cd_demo_sk
JOIN 
    income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE 
    sa.rank_within_band <= 5
ORDER BY 
    ib.ib_lower_bound, sa.total_sales DESC;
