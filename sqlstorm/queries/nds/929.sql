
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CA.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
      AND cd.cd_gender IS NOT NULL
),

TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_purchase_estimate
    FROM CustomerData c
    WHERE c.rank <= 5
),

SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),

FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        tc.cd_marital_status,
        COALESCE(sd.total_net_paid, 0) AS total_net_paid,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sd.total_orders, 0) AS total_orders,
        CASE 
            WHEN sd.total_net_paid > 1000 THEN 'High Value'
            WHEN sd.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM TopCustomers tc
    LEFT JOIN SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
)

SELECT 
    f.c_customer_sk,
    CONCAT(f.c_first_name, ' ', f.c_last_name) AS full_name,
    f.cd_gender,
    f.cd_marital_status,
    f.total_net_paid,
    f.total_quantity_sold,
    f.total_orders,
    f.customer_value_category,
    DENSE_RANK() OVER (ORDER BY f.total_net_paid DESC) AS sales_rank
FROM FinalReport f
ORDER BY f.total_net_paid DESC;
