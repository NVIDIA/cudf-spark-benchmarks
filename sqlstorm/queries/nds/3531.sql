
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 10000 AND 20000
    GROUP BY 
        ws.ws_item_sk
),
returns_info AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ri.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ri.total_return_amount, 0) AS total_return_amount,
    (COALESCE(ss.total_sales, 0) - COALESCE(ri.total_return_amount, 0)) AS net_revenue
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    returns_info ri ON ss.ws_item_sk = ri.wr_item_sk
WHERE 
    ci.cd_purchase_estimate > 500
ORDER BY 
    net_revenue DESC
LIMIT 100;
