
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_net_paid
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2022 AND 2023
),
HighValueCustomers AS (
    SELECT 
        c_first_name,
        c_last_name,
        ca_city,
        ca_state,
        COUNT(*) AS purchase_count,
        SUM(ws_net_paid) AS total_spent
    FROM 
        SalesData
    GROUP BY 
        c_first_name, c_last_name, ca_city, ca_state
    HAVING 
        SUM(ws_net_paid) > 1000
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.ca_city,
    hvc.ca_state,
    hvc.purchase_count,
    hvc.total_spent
FROM 
    HighValueCustomers hvc
ORDER BY 
    hvc.total_spent DESC
LIMIT 10;
