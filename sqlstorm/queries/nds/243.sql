
WITH customer_counts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
        COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
return_stats AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
final_report AS (
    SELECT 
        cc.c_customer_sk,
        cc.total_catalog_sales,
        cc.total_web_sales,
        rs.total_return_amount,
        rs.total_catalog_return_amount,
        COALESCE(cc.total_web_sales, 0) - COALESCE(rs.total_return_amount, 0) AS adjusted_web_sales,
        COALESCE(cc.total_catalog_sales, 0) - COALESCE(rs.total_catalog_return_amount, 0) AS adjusted_catalog_sales
    FROM 
        customer_counts cc
    JOIN 
        return_stats rs ON cc.c_customer_sk = rs.c_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.total_catalog_sales,
    f.total_web_sales,
    f.total_return_amount,
    f.total_catalog_return_amount,
    f.adjusted_web_sales,
    f.adjusted_catalog_sales,
    CASE 
        WHEN f.adjusted_web_sales > 5000 THEN 'High Value Customer'
        WHEN f.adjusted_web_sales BETWEEN 2000 AND 5000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    final_report f
WHERE 
    f.total_catalog_sales > 10 
ORDER BY 
    f.adjusted_web_sales DESC, f.adjusted_catalog_sales DESC
LIMIT 100;
