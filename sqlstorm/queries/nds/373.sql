
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopSpendings AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSales cs
),
ReturnedSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_returns,
        COUNT(ws.ws_order_number) AS return_count
    FROM 
        web_sales ws
    JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ts.c_first_name,
    ts.c_last_name,
    ts.total_spent,
    ts.total_orders,
    COALESCE(rs.total_returns, 0) AS total_returns,
    ts.total_spent - COALESCE(rs.total_returns, 0) AS net_spending
FROM 
    TopSpendings ts
LEFT JOIN 
    ReturnedSales rs ON ts.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    ts.spend_rank <= 10
ORDER BY 
    ts.total_spent DESC;
