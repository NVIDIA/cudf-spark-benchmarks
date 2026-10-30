
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(ws.ws_item_sk) AS items_sold
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
    GROUP BY 
        ws.ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        sd.total_profit,
        sd.total_orders,
        sd.items_sold
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        SalesData sd ON rc.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        rc.rnk <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_profit, 0) AS total_profit,
    COALESCE(tc.total_orders, 0) AS total_orders,
    COALESCE(tc.items_sold, 0) AS items_sold,
    CASE 
        WHEN tc.total_profit > 1000 THEN 'High Value'
        WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_band
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_profit DESC;
