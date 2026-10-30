
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_sales_price) AS total_sales, 
        SUM(ws_ext_discount_amt) AS total_discount, 
        COUNT(*) AS transaction_count
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231 
    GROUP BY 
        ws_bill_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COALESCE(sd.total_sales, 0) AS total_sales, 
        COALESCE(sd.total_discount, 0) AS total_discount, 
        sd.transaction_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.cd_gender, 
    cs.cd_marital_status, 
    cs.total_sales, 
    cs.total_discount, 
    cs.transaction_count,
    CASE 
        WHEN cs.total_sales > 10000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerStats cs
WHERE 
    cs.transaction_count > 0
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
