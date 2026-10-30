
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_web_page_sk) AS unique_web_pages
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY ws_bill_customer_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CombinedData AS (
    SELECT 
        cust.c_customer_sk,
        cust.c_first_name,
        cust.c_last_name,
        cust.cd_gender,
        cust.cd_marital_status,
        cust.cd_education_status,
        cust.cd_credit_rating,
        sales.total_sales,
        sales.total_orders,
        sales.total_profit,
        sales.unique_web_pages
    FROM CustomerData cust
    LEFT JOIN SalesData sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_sales,
    cd.total_orders,
    cd.total_profit,
    cd.unique_web_pages
FROM CombinedData cd
WHERE cd.total_sales > 5000
ORDER BY cd.total_profit DESC
LIMIT 50;
