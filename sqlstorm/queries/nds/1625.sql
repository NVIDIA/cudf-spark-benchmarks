
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        sd.total_sales,
        sd.order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        sd.sales_rank <= 10
),
AddressCounts AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
    GROUP BY 
        ca.ca_city
),
FinalReport AS (
    SELECT 
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.gender,
        hvc.total_sales,
        a.customer_count,
        CASE 
            WHEN hvc.total_sales > 1000 THEN 'High Value'
            ELSE 'Standard'
        END AS customer_type
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        AddressCounts a ON a.customer_count > 1
)
SELECT 
    *
FROM 
    FinalReport
ORDER BY 
    total_sales DESC;
