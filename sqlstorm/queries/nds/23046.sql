
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) as rank_order
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 0
),
Item_Summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COUNT(DISTINCT cte.ws_order_number) AS total_orders,
        SUM(cte.ws_quantity) AS total_quantity_sold,
        SUM(cte.ws_net_paid) AS total_revenue,
        AVG(cte.ws_net_paid) AS avg_revenue
    FROM 
        Sales_CTE cte
    JOIN 
        item i ON cte.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(s.ss_net_paid), 0) AS total_spent,
        COUNT(DISTINCT s.ss_ticket_number) AS number_of_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Return_Stats AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS num_returns,
        SUM(wr_return_amt) AS total_return_amount,
        RANK() OVER (ORDER BY SUM(wr_return_amt) DESC) AS return_rank
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    isum.total_orders,
    isum.total_quantity_sold,
    isum.total_revenue,
    isum.avg_revenue,
    COALESCE(rs.num_returns, 0) AS returns_count,
    COALESCE(rs.total_return_amount, 0) AS returns_total,
    CASE 
        WHEN rs.num_returns IS NULL THEN 'No Returns'
        WHEN rs.total_return_amount > 0 THEN 'Frequent Returner'
        ELSE 'Rare Returner'
    END AS return_behavior
FROM 
    Customer_Stats cs
JOIN 
    Item_Summary isum ON cs.total_spent > 1000
LEFT JOIN 
    Return_Stats rs ON cs.c_customer_sk = rs.wr_returning_customer_sk
WHERE 
    isum.total_revenue BETWEEN 500 AND 10000
ORDER BY 
    isum.total_revenue DESC,
    cs.number_of_transactions DESC
LIMIT 50;
