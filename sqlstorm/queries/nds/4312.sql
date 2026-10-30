
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ci.cd_gender,
        ci.cd_purchase_estimate
    FROM 
        customer_info ci
    JOIN 
        customer c ON ci.c_customer_sk = c.c_customer_sk
    WHERE 
        ci.purchase_rank <= 10
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) as order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) as return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0) AS net_sales,
    CASE 
        WHEN COALESCE(ss.total_sales, 0) = 0 THEN 0
        ELSE ROUND((COALESCE(rs.total_returns, 0) / COALESCE(ss.total_sales, 0)) * 100, 2) 
    END AS return_percentage
FROM 
    top_customers tc
LEFT JOIN 
    sales_summary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    returns_summary rs ON tc.c_customer_sk = rs.wr_returning_customer_sk
WHERE 
    tc.cd_gender = 'F' AND (COALESCE(ss.total_sales, 0) > 100 OR COALESCE(rs.total_returns, 0) > 5)
ORDER BY 
    net_sales DESC;
