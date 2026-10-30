WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year >= 1998 AND 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        d.d_year, d.d_month_seq, c.c_customer_id
),
ranked_sales AS (
    SELECT 
        ss.d_year,
        ss.d_month_seq,
        ss.c_customer_id,
        ss.total_quantity,
        ss.total_profit,
        ss.order_count,
        RANK() OVER (PARTITION BY ss.d_year ORDER BY ss.total_profit DESC) AS profit_rank
    FROM 
        sales_summary ss
)
SELECT 
    r.d_year,
    r.d_month_seq,
    r.c_customer_id,
    r.total_quantity,
    r.total_profit,
    r.order_count,
    CASE WHEN r.profit_rank <= 10 THEN 'Top 10' ELSE 'Other' END AS ranking
FROM 
    ranked_sales r
WHERE 
    r.total_profit IS NOT NULL 
    AND r.total_quantity > 0
ORDER BY 
    r.d_year, r.d_month_seq, r.profit_rank;