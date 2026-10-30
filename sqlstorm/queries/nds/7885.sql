
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
), sales_summary AS (
    SELECT 
        dd.d_date AS sales_date,
        sd.total_net_profit,
        sd.total_orders,
        sd.avg_order_value
    FROM 
        date_dim dd
    JOIN 
        sales_data sd ON dd.d_date_sk = sd.ws_sold_date_sk
), demographics_sales AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ss.sales_date,
        ss.total_net_profit,
        ss.total_orders,
        ss.avg_order_value
    FROM 
        customer_info ci
    JOIN 
        sales_summary ss ON ci.c_customer_sk IN (
            SELECT 
                ws.ws_bill_customer_sk
            FROM 
                web_sales ws
            WHERE 
                ws.ws_ship_date_sk IN (
                    SELECT 
                        d.d_date_sk 
                    FROM 
                        date_dim d 
                    WHERE 
                        d.d_year = 2023
                )
        )
)
SELECT 
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(*) AS customer_count,
    SUM(ss.total_net_profit) AS total_net_profit,
    AVG(ss.avg_order_value) AS avg_order_value,
    MIN(ss.sales_date) AS first_purchase_date,
    MAX(ss.sales_date) AS last_purchase_date
FROM 
    demographics_sales ss
JOIN 
    customer_info ci ON ss.c_first_name = ci.c_first_name AND ss.c_last_name = ci.c_last_name
GROUP BY 
    ci.cd_gender, ci.cd_marital_status
ORDER BY 
    total_net_profit DESC;
