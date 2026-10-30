WITH CustomerOrderStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
ProfitRanking AS (
    SELECT 
        cos.c_customer_sk,
        cos.total_orders,
        cos.total_profit,
        DENSE_RANK() OVER (ORDER BY cos.total_profit DESC) AS profit_rank
    FROM 
        CustomerOrderStats AS cos
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    p.total_orders,
    p.total_profit,
    p.profit_rank,
    COALESCE(d.d_month_seq, 0) AS month_seq,
    CASE 
        WHEN p.total_profit IS NULL THEN 'No Profit'
        WHEN p.total_profit < 100 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    ProfitRanking AS p
JOIN 
    customer AS c ON p.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    date_dim AS d ON d.d_date_sk = (SELECT MAX(d2.d_date_sk)
                                      FROM date_dim AS d2 
                                      WHERE d2.d_year = 2001)
WHERE 
    p.profit_rank <= 10
ORDER BY 
    p.total_profit DESC;