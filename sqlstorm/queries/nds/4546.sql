
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity_sold,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(ss.ss_net_paid_inc_tax, 0)) AS total_net_paid
    FROM customer c 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), sales_ranked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_quantity_sold,
        cs.total_net_paid,
        DENSE_RANK() OVER (ORDER BY cs.total_net_paid DESC) AS revenue_rank
    FROM customer_sales cs
), top_customers AS (
    SELECT 
        tr.c_customer_sk,
        tr.c_first_name,
        tr.c_last_name,
        tr.total_quantity_sold,
        tr.total_net_paid,
        rd.r_reason_desc
    FROM sales_ranked tr
    LEFT JOIN store_returns sr ON tr.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN reason rd ON sr.sr_reason_sk = rd.r_reason_sk
    WHERE tr.revenue_rank <= 10
), final_output AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        COALESCE(tc.total_quantity_sold, 0) AS total_quantity,
        COALESCE(tc.total_net_paid, 0.00) AS total_paid,
        COALESCE(tc.r_reason_desc, 'No Returns') AS return_reason
    FROM top_customers tc
)
SELECT 
    fo.c_customer_sk,
    fo.c_first_name,
    fo.c_last_name,
    fo.total_quantity,
    fo.total_paid,
    fo.return_reason
FROM final_output fo
ORDER BY fo.total_paid DESC;
