
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.cd_gender,
    COALESCE(ss.total_web_sales, 0) AS total_web_sales,
    COALESCE(sr.total_web_returns, 0) AS total_web_returns,
    COALESCE(ss.total_web_sales, 0) - COALESCE(sr.total_web_returns, 0) AS net_sales,
    CASE 
        WHEN cs.purchase_rank <= 10 THEN 'Top Buyer'
        ELSE 'Regular Buyer'
    END AS buyer_category
FROM 
    customer_stats cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN 
    return_summary sr ON cs.c_customer_sk = sr.wr_returning_customer_sk
WHERE 
    (cs.purchase_rank <= 10 OR (COALESCE(ss.total_web_sales, 0) - COALESCE(sr.total_web_returns, 0)) > 1000) 
    AND cs.cd_marital_status = 'M'
ORDER BY 
    net_sales DESC;
