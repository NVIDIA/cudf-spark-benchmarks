
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY ws_bill_customer_sk, ws_ship_customer_sk, ws_item_sk
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT cd_demo_sk) AS total_demos,
        SUM(hd_vehicle_count) AS total_vehicles
    FROM customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    GROUP BY c_customer_sk
),
FinalData AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_net_paid, 0) AS total_net_paid,
        COALESCE(sd.avg_sales_price, 0) AS avg_sales_price,
        COALESCE(cd.total_demos, 0) AS total_demos,
        COALESCE(cd.total_vehicles, 0) AS total_vehicles
    FROM customer c
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN CustomerData cd ON c.c_customer_sk = cd.c_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.total_quantity,
    f.total_net_paid,
    f.avg_sales_price,
    f.total_demos,
    f.total_vehicles,
    CASE 
        WHEN f.total_net_paid > 1000 THEN 'High Value Customer'
        WHEN f.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM FinalData f
ORDER BY f.total_net_paid DESC
LIMIT 100;
