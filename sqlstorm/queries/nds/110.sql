
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
return_summary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_net_loss) AS total_net_loss,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(rs.total_net_loss, 0) AS total_net_loss,
        CASE 
            WHEN COALESCE(ss.total_net_profit, 0) > 0 THEN 'Profitable Customer'
            WHEN COALESCE(rs.total_net_loss, 0) > 0 THEN 'Return Customer'
            ELSE 'Neutral Customer'
        END AS customer_type
    FROM 
        customer c
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN return_summary rs ON c.c_customer_sk = rs.wr_returning_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_net_profit,
    cs.total_net_loss,
    cs.customer_type,
    RANK() OVER (ORDER BY cs.total_net_profit DESC) AS profit_rank
FROM 
    customer_stats cs
WHERE 
    (cs.total_net_profit > 1000 OR cs.total_net_loss > 500)
ORDER BY 
    cs.customer_type, cs.total_net_profit DESC;
