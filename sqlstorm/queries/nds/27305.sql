
WITH FilteredCustomer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city LIKE '%Springfield%' 
        AND cd.cd_gender = 'M'
),
AggregatedSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    FC.c_first_name || ' ' || FC.c_last_name AS full_name,
    FC.ca_city,
    FC.ca_state,
    CS.total_orders,
    CS.total_sales
FROM 
    FilteredCustomer FC
LEFT JOIN 
    AggregatedSales CS ON FC.c_customer_sk = CS.ws_bill_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 10;
