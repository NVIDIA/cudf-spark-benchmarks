WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_per_gender
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_return_amt) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) AS net_sales
    FROM 
        customer_stats cs
    LEFT JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.customer_sk
    LEFT JOIN 
        returns_summary rs ON cs.c_customer_sk = rs.customer_sk
    WHERE 
        cs.rank_per_gender <= 5
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.total_sales,
    fs.total_returns,
    fs.net_sales,
    CASE 
        WHEN fs.net_sales > 1000 THEN 'High Value'
        WHEN fs.net_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    final_summary fs
ORDER BY 
    fs.total_sales DESC;