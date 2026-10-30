
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_bill_customer_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_first_name, 
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    sd.total_sales,
    sd.total_discount,
    sd.total_tax,
    sd.order_count
FROM 
    CustomerData cd
JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
