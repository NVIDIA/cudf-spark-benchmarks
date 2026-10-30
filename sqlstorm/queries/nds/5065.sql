
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit,
        MAX(ws_sales_price) AS max_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy BETWEEN 6 AND 8)
    GROUP BY 
        ws_bill_customer_sk
),
demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
combined_data AS (
    SELECT 
        ss.customer_id,
        ss.total_sales,
        ss.total_orders,
        ss.avg_profit,
        ss.max_sales_price,
        d.cd_gender,
        d.cd_marital_status,
        d.ib_lower_bound,
        d.ib_upper_bound
    FROM 
        sales_summary ss
    JOIN 
        demographics d ON ss.customer_id = d.c_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(*) AS number_of_customers,
    AVG(cd.total_sales) AS avg_sales,
    SUM(cd.total_orders) AS total_orders,
    SUM(cd.avg_profit) AS total_profit,
    MIN(cd.max_sales_price) AS min_max_sales_price,
    MAX(cd.max_sales_price) AS max_max_sales_price
FROM 
    combined_data cd
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    number_of_customers DESC, 
    avg_sales DESC
LIMIT 10;
