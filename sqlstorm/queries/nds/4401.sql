
WITH SalesData AS (
    SELECT 
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        c.c_customer_id,
        cd.cd_gender,
        d.d_year,
        sm.sm_type,
        ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY ws.ws_net_paid DESC) as rank 
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year >= 2020
    AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS total_sales
    FROM SalesData
    WHERE rank <= 10
    GROUP BY c_customer_id
    HAVING SUM(ws_net_profit) > 1000
)
SELECT 
    tc.c_customer_id,
    tc.total_profit,
    tc.total_sales,
    COALESCE(SUM(sd.ws_quantity), 0) AS total_quantity_sold
FROM TopCustomers tc
LEFT JOIN SalesData sd ON tc.c_customer_id = sd.c_customer_id
GROUP BY tc.c_customer_id, tc.total_profit, tc.total_sales
ORDER BY tc.total_profit DESC
LIMIT 5;
