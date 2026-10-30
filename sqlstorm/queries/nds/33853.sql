
WITH  sales_cte AS (
    SELECT 
        ws_sold_date_sk, 
        ws_web_site_sk, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_web_site_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
returns_summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
sales_analysis AS (
    SELECT 
        si.i_item_sk,
        COALESCE(CAST(SUM(ss.ss_net_paid) AS DECIMAL(10, 2)), 0) AS total_store_sales,
        COALESCE(CAST(SUM(ws.ws_net_paid) AS DECIMAL(10, 2)), 0) AS total_web_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS return_value
    FROM 
        item si
    LEFT JOIN 
        store_sales ss ON si.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        web_sales ws ON si.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        returns_summary rs ON si.i_item_sk = rs.sr_item_sk
    GROUP BY 
        si.i_item_sk, rs.total_returns, rs.total_return_value
)
SELECT 
    s.i_item_sk,
    s.total_store_sales,
    s.total_web_sales,
    s.total_returns,
    s.return_value,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate
FROM 
    sales_analysis s
JOIN 
    customer_info ci ON ci.gender_rank = 1
WHERE 
    (s.total_web_sales > 5000 OR s.total_store_sales > 5000)
ORDER BY 
    s.total_store_sales DESC, 
    s.total_web_sales DESC 
LIMIT 100;
