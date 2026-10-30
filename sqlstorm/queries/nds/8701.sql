
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        ci.c_customer_sk
),
return_summary AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ss.total_sales,
    ss.order_count,
    COALESCE(rs.return_count, 0) AS return_count,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.c_customer_sk
LEFT JOIN 
    return_summary rs ON ci.c_customer_sk = rs.sr_customer_sk
WHERE 
    ci.cd_marital_status = 'M' 
    AND ci.cd_purchase_estimate > 1000
ORDER BY 
    total_sales DESC
LIMIT 50;
