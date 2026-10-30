
WITH Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
Return_Summary AS (
    SELECT 
        cr.cr_returning_customer_sk,
        COUNT(cr.cr_returned_time_sk) AS total_returns,
        SUM(cr.cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_returning_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    cs.total_sales,
    cs.total_orders,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount
FROM 
    Customer_Summary cs
LEFT JOIN 
    Return_Summary rs ON cs.c_customer_sk = rs.cr_returning_customer_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
