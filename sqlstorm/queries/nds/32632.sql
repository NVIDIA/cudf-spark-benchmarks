
WITH  sales_summary AS (
    SELECT
        w.w_warehouse_id,
        i.i_item_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS total_sales_count,
        RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    WHERE ss.ss_sales_price > 0
    GROUP BY w.w_warehouse_id, i.i_item_id
),
customer_summary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT
        cus.c_customer_id,
        cus.total_spent,
        ROW_NUMBER() OVER (ORDER BY cus.total_spent DESC) AS customer_rank
    FROM customer_summary cus
)
SELECT
    ss.w_warehouse_id,
    ts.c_customer_id,
    ts.total_spent,
    ss.total_sales_count,
    ss.total_net_profit,
    CASE
        WHEN ss.total_sales_count > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM sales_summary ss
JOIN top_customers ts ON ts.customer_rank <= 10
WHERE ss.profit_rank <= 5
ORDER BY ss.w_warehouse_id, ts.total_spent DESC;
