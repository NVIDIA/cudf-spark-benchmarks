
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.cd_credit_rating,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.avg_sales, 0) AS avg_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    COALESCE(rs.total_returns, 0) AS total_returns,
    ci.hd_income_band_sk,
    ci.hd_buy_potential,
    ci.hd_dep_count,
    ci.hd_vehicle_count
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    returns_summary rs ON ci.c_customer_sk = rs.wr_returning_customer_sk
WHERE 
    ci.cd_gender = 'F'
    AND ci.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC, 
    ci.c_last_name ASC
LIMIT 100;
