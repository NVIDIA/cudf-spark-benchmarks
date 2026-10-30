
WITH CustomerRanking AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM CustomerRanking cr
    JOIN web_sales ws ON cr.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cr.rank <= 10
    GROUP BY cr.c_customer_sk, cr.c_first_name, cr.c_last_name
)
SELECT 
    t1.c_first_name,
    t1.c_last_name,
    t1.total_sales,
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_profit) AS average_profit
FROM TopCustomers t1
JOIN customer c ON t1.c_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY t1.c_first_name, t1.c_last_name, t1.total_sales, ca.ca_state, ca.ca_city
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY t1.total_sales DESC;
