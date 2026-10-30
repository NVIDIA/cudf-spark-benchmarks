
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        CASE 
            WHEN SUM(ss.ss_net_paid) > 1000 THEN 'High'
            WHEN SUM(ss.ss_net_paid) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS spending_category
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), warehouse_metrics AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_item_sk) AS item_count
    FROM 
        warehouse w
        JOIN store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
), return_summary AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), final_report AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_spent,
        cs.purchase_count,
        wm.w_warehouse_name,
        wm.total_profit,
        wm.item_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        customer_summary cs
        LEFT JOIN warehouse_metrics wm ON 1=1  -- Changed to join condition
        LEFT JOIN return_summary rs ON cs.c_customer_sk = rs.sr_customer_sk
)
SELECT 
    *
FROM 
    final_report
WHERE 
    (total_spent > 500 OR total_returns > 0)
ORDER BY 
    total_spent DESC, total_returns DESC
LIMIT 100;  -- Changed FETCH FIRST to LIMIT for compatibility
