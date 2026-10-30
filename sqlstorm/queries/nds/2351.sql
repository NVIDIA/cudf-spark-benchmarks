
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sales_price) AS max_sales_price,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ReturnStats AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_returned_amount,
        COUNT(cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CombinedStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.order_count,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(rs.return_count, 0) AS return_count,
        (cs.total_web_sales - COALESCE(rs.total_returned_amount, 0)) AS net_sales
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ReturnStats rs ON cs.c_customer_sk = rs.cr_returning_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cs.total_web_sales,
    cs.order_count,
    cs.total_returned_amount,
    cs.return_count,
    cs.net_sales,
    CASE 
        WHEN cs.net_sales >= 1000 THEN 'High Value Customer'
        WHEN cs.net_sales >= 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    CombinedStats cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    cs.net_sales > 0
ORDER BY 
    cs.net_sales DESC
LIMIT 100;
