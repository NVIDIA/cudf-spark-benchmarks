
WITH CustomerPurchaseDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
HighValueCustomers AS (
    SELECT 
        cpd.c_customer_sk,
        cpd.c_first_name,
        cpd.c_last_name,
        cpd.total_sales,
        cpd.order_count,
        ca.ca_city,
        ca.ca_state
    FROM 
        CustomerPurchaseDetails AS cpd
    JOIN 
        customer_address AS ca ON cpd.c_customer_sk = ca.ca_address_sk
    WHERE 
        cpd.total_sales > (SELECT AVG(total_sales) FROM CustomerPurchaseDetails)
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    hvc.ca_city,
    hvc.ca_state,
    CASE
        WHEN hvc.total_sales > 1000 THEN 'High Value'
        WHEN hvc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    HighValueCustomers AS hvc
WHERE 
    hvc.ca_state IS NOT NULL
ORDER BY 
    hvc.total_sales DESC
LIMIT 10;
