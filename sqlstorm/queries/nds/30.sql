
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        s.s_store_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE ws.ws_sold_date_sk >= 20210101
    GROUP BY w.w_warehouse_id, s.s_store_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE cd.cd_marital_status = 'M' 
      AND cd.cd_credit_rating = 'High'
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
returns_summary AS (
    SELECT 
        cr_reason_sk,
        COUNT(*) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(cr_return_tax) AS avg_return_tax
    FROM catalog_returns
    GROUP BY cr_reason_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.total_orders,
        cs.total_spent,
        ss.total_sales,
        ss.order_count,
        ss.avg_net_paid,
        rs.return_count,
        rs.total_return_amount,
        rs.avg_return_tax
    FROM customer_summary cs
    LEFT JOIN sales_summary ss ON cs.total_orders > 0
    LEFT JOIN returns_summary rs ON cs.total_orders > 0
    WHERE cs.total_spent > 1000
)
SELECT 
    fs.c_customer_id,
    fs.cd_gender,
    fs.total_orders,
    fs.total_spent,
    COALESCE(fs.total_sales, 0) AS total_sales,
    COALESCE(fs.order_count, 0) AS order_count,
    COALESCE(fs.avg_net_paid, 0) AS avg_net_paid,
    COALESCE(fs.return_count, 0) AS return_count,
    COALESCE(fs.total_return_amount, 0) AS total_return_amount,
    COALESCE(fs.avg_return_tax, 0) AS avg_return_tax
FROM final_summary fs
ORDER BY fs.total_spent DESC, fs.total_orders DESC;
