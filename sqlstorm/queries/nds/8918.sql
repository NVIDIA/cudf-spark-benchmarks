
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        cs.*,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_stats cs
    WHERE total_orders > 0
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.cd_gender,
    t.cd_marital_status,
    t.cd_education_status,
    t.total_orders,
    t.total_sales,
    t.average_profit,
    w.w_warehouse_name,
    r.r_reason_desc
FROM top_customers t
JOIN store_sales ss ON t.c_customer_sk = ss.ss_customer_sk
JOIN reason r ON ss.ss_ext_discount_amt > 0 AND r.r_reason_sk = ss.ss_ticket_number % 10
JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
WHERE t.sales_rank <= 10
ORDER BY t.total_sales DESC, t.c_last_name, t.c_first_name;
