
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S')
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
final_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ss.total_quantity,
        ss.total_sales,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_returned, 0) AS total_returned,
        CASE 
            WHEN ss.order_count > 5 AND rs.return_count > 0 THEN 'Loyalty In Question'
            WHEN ss.order_count > 5 AND rs.return_count = 0 THEN 'Loyal Customer'
            ELSE 'Potential Customer'
        END AS customer_status
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN 
        returns_summary rs ON ci.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.total_quantity,
    f.total_sales,
    f.return_count,
    f.total_returned,
    f.customer_status
FROM 
    final_summary f
WHERE 
    (f.cd_gender = 'F' AND f.total_sales > 1000) 
    OR (f.cd_gender = 'M' AND f.return_count = 0)
ORDER BY 
    f.total_sales DESC, 
    f.c_last_name ASC
LIMIT 100;

