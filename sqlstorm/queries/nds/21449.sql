WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid) AS average_net_paid
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 AND
        dd.d_dow IN (6, 7)  
    GROUP BY 
        ws.ws_item_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(COALESCE(ws.ws_net_paid, 0)) > 1000
),
recent_returns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk > (SELECT MAX(dd.d_date_sk) 
                                   FROM date_dim dd 
                                   WHERE dd.d_year = 2001) - 30
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(s.total_quantity, 0) AS weekend_sales_quantity,
    COALESCE(c.total_spent, 0) AS customer_spending,
    COALESCE(r.return_count, 0) AS recent_return_count,
    CASE 
        WHEN r.return_count IS NULL THEN 'No Returns'
        WHEN r.total_return_amount > (0.1 * s.total_quantity) THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_status,
    (CASE
        WHEN s.total_quantity > 100 THEN 'High Demand'
        ELSE 'Normal Demand'
     END || ' / ' || 
     COALESCE(ROUND(s.total_net_profit, 2), 0)) AS profitability_status
FROM 
    item i
LEFT JOIN 
    ranked_sales s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    high_value_customers c ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    recent_returns r ON r.sr_item_sk = i.i_item_sk
WHERE 
    (s.rank_quantity <= 5 OR s.rank_quantity IS NULL)
ORDER BY 
    profitability_status DESC, 
    i.i_item_id;