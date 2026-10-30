
WITH CustomerStatistics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ARRAY_AGG(DISTINCT CONCAT(ca.ca_city, ', ', ca.ca_state)) AS address_list,
        COUNT(DISTINCT fs.ws_order_number) AS total_orders,
        SUM(fs.ws_sales_price) AS total_spent,
        AVG(fs.ws_sales_price) AS avg_order_value
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales fs ON c.c_customer_sk = fs.ws_bill_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenderCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.avg_order_value
    FROM CustomerStatistics cs
    WHERE cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStatistics)
),
OrderCounts AS (
    SELECT 
        cs.c_customer_sk,
        COUNT(fs.ws_order_number) AS order_frequency
    FROM CustomerStatistics cs
    JOIN web_sales fs ON cs.c_customer_sk = fs.ws_bill_customer_sk
    GROUP BY cs.c_customer_sk
)
SELECT
    hsc.c_customer_sk,
    hsc.c_first_name,
    hsc.c_last_name,
    hsc.total_orders,
    hsc.total_spent,
    hsc.avg_order_value,
    oc.order_frequency
FROM HighSpenderCustomers hsc
JOIN OrderCounts oc ON hsc.c_customer_sk = oc.c_customer_sk
ORDER BY hsc.total_spent DESC, order_frequency DESC
LIMIT 50;
