
WITH customer_sales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(ws.ws_quantity) AS total_items,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax
    FROM 
        customer c 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_id, 
        cs.total_net_paid,
        RANK() OVER (ORDER BY cs.total_net_paid DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE cs.total_net_paid IS NOT NULL
    AND cs.total_orders > (SELECT AVG(total_orders) FROM customer_sales)
),
returns_summary AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_returns_amt
    FROM 
        store_returns sr
    WHERE 
        sr_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'F'))
),
final_summary AS (
    SELECT 
        hvc.c_customer_id,
        hvc.sales_rank,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returns_amt, 0) AS total_returns_amt,
        CASE 
            WHEN hvc.total_net_paid > 1000 THEN 'High Value'
            WHEN hvc.total_net_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        high_value_customers hvc
    LEFT JOIN returns_summary rs ON true 
)
SELECT 
    f.c_customer_id,
    f.sales_rank,
    f.total_returns,
    f.total_returns_amt,
    f.customer_value_segment,
    CASE 
        WHEN f.total_returns > 5 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS return_frequency,
    ROW_NUMBER() OVER (PARTITION BY f.customer_value_segment ORDER BY f.sales_rank) AS segment_rank
FROM final_summary f
WHERE f.total_returns_amt IS NOT NULL
ORDER BY f.customer_value_segment, f.sales_rank DESC
LIMIT 100;
