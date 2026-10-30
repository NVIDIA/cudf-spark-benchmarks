
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        R.total_sales,
        R.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        RankedSales R
    JOIN 
        customer c ON R.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        R.rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.ca_city,
    tc.ca_state
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_sales DESC;
