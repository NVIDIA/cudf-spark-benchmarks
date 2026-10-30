
WITH customer_returns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (
            SELECT 
                AVG(cd2.cd_purchase_estimate) 
            FROM 
                customer_demographics cd2
        )
),
recent_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > (
            SELECT 
                MAX(d_date_sk) - 30 
            FROM 
                date_dim
        )
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COALESCE(cr.total_returns, 0) AS customer_total_returns,
    COALESCE(cr.total_return_amount, 0) AS customer_total_return_amount,
    COALESCE(rs.total_sales, 0) AS recent_sales_total
FROM 
    high_value_customers hvc
LEFT JOIN 
    customer_returns cr ON hvc.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    recent_sales rs ON hvc.c_customer_sk = rs.ws_bill_customer_sk
ORDER BY 
    hvc.c_last_name, hvc.c_first_name;
