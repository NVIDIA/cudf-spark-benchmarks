
WITH sales_summary AS (
    SELECT 
        c.c_current_cdemo_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws 
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458849 AND 2459200
    GROUP BY 
        c.c_current_cdemo_sk
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_income_band_sk IS NULL THEN 'Unknown' 
            ELSE 'Known' 
        END AS income_status
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_with_demo AS (
    SELECT 
        ss.c_current_cdemo_sk,
        ss.total_sales,
        ss.total_orders,
        ss.avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_status
    FROM 
        sales_summary ss 
    JOIN 
        customer_demo cd ON ss.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    income_status,
    cd_gender,
    cd_marital_status,
    COUNT(*) AS num_customers,
    SUM(total_sales) AS total_sales,
    SUM(total_orders) AS total_orders,
    AVG(avg_order_value) AS avg_order_value
FROM 
    sales_with_demo
GROUP BY 
    income_status, cd_gender, cd_marital_status
ORDER BY 
    income_status, cd_gender, cd_marital_status;
