
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS customer_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451913 AND 2451915
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count,
        cs.avg_order_value
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.customer_rank <= 100
),
SalesStats AS (
    SELECT 
        MAX(total_spent) AS max_spent,
        MIN(total_spent) AS min_spent,
        AVG(total_spent) AS avg_spent
    FROM TopCustomers
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS store_revenue
    FROM store s
    JOIN web_sales ws ON s.s_store_sk = ws.ws_ship_addr_sk
    GROUP BY s.s_store_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.total_spent) AS demographic_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY cd.cd_gender
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    ss.max_spent,
    ss.min_spent,
    ss.avg_spent,
    si.total_orders AS store_orders,
    si.store_revenue,
    cd.demographic_spent,
    cd.customer_count
FROM TopCustomers tc
CROSS JOIN SalesStats ss
JOIN StoreInfo si ON si.total_orders > 0
JOIN CustomerDemographics cd ON cd.customer_count > 0
WHERE tc.total_spent > (SELECT AVG(total_spent) FROM TopCustomers) 
    AND si.store_revenue IS NOT NULL
ORDER BY tc.total_spent DESC;
