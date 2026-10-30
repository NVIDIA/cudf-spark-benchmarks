
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        HD.hd_income_band_sk,
        COALESCE(HD.hd_dep_count, 0) AS dependent_count,
        COALESCE(HD.hd_vehicle_count, 0) AS vehicle_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics HD ON c.c_customer_sk = HD.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        CAST(dd.d_date AS DATE) AS sales_date
    FROM 
        web_sales 
    JOIN 
        date_dim dd ON ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws_bill_customer_sk, dd.d_date
),
returns_summary AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_returns 
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(ss.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    cs.dependent_count,
    cs.vehicle_count,
    CASE 
        WHEN cs.gender_rank <= 10 THEN 'Top Spender'
        ELSE 'Regular Spender'
    END AS customer_category
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    returns_summary rs ON cs.c_customer_sk = rs.sr_customer_sk
WHERE 
    COALESCE(ss.total_sales_profit, 0) > 1000
    OR cs.vehicle_count > 0
ORDER BY 
    cs.c_last_name, cs.c_first_name;
