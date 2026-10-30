
WITH DetailedCustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        CONCAT(cu.c_first_name, ' ', cu.c_last_name) AS customer_name,
        cu.c_email_address,
        cu.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cu.c_customer_sk  -- added to prevent error in the join
    FROM 
        customer_address ca
    JOIN 
        customer cu ON cu.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
),
DateFilteredSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ship_date_sk DESC) AS ship_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
AggregatedSales AS (
    SELECT 
        df.full_address,
        COUNT(DISTINCT ds.ws_order_number) AS total_orders,
        COUNT(ds.ws_order_number) AS total_items_ordered
    FROM 
        DetailedCustomerAddresses df
    JOIN 
        DateFilteredSales ds ON ds.ws_order_number IN (
            SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = df.c_customer_sk  -- fixed this line
        )
    GROUP BY 
        df.full_address
)
SELECT 
    full_address,
    total_orders,
    total_items_ordered,
    CASE 
        WHEN total_orders > 10 THEN 'High Value Customer'
        WHEN total_orders BETWEEN 5 AND 10 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    AggregatedSales
ORDER BY 
    total_orders DESC, total_items_ordered DESC;
