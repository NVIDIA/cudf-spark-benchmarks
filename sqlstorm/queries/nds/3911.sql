
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
returns_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.purchase_estimate,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_orders, 0) AS total_orders,
    COALESCE(rs.total_returns, 0) AS total_returns,
    CASE 
        WHEN ss.sales_rank IS NULL THEN 'No Sales'
        ELSE 'Rank: ' || ss.sales_rank 
    END AS sales_status,
    CASE 
        WHEN cs.purchase_estimate >= 1000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS customer_value
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    returns_summary rs ON cs.c_customer_sk = rs.wr_returning_customer_sk
WHERE 
    (cs.cd_gender = 'F' OR cs.purchase_estimate > 500)
    AND (cs.income_band IS NOT NULL OR cs.purchase_estimate > 0)
ORDER BY 
    total_sales DESC, 
    total_orders DESC
LIMIT 100;
