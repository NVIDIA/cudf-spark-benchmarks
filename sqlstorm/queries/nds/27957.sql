
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        cd_gender, 
        cd_marital_status, 
        cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name, 
        ai.full_address, 
        ai.ca_city, 
        ai.ca_state, 
        sd.total_sales, 
        sd.order_count,
        (CASE 
            WHEN sd.total_sales IS NULL THEN 'No Sales' 
            ELSE 
                (CASE 
                    WHEN sd.total_sales > 1000 THEN 'High Value' 
                    WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value' 
                    ELSE 'Low Value' 
                END) 
        END) AS customer_value
    FROM 
        CustomerInfo ci
    JOIN 
        AddressInfo ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.customer_sk
)
SELECT 
    customer_value,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS average_sales,
    SUM(order_count) AS total_orders
FROM 
    CustomerBenchmark
GROUP BY 
    customer_value
ORDER BY 
    customer_value;
