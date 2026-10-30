
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
),
StoreSalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    rs.c_first_name, 
    rs.c_last_name, 
    rs.total_net_profit, 
    rs.total_orders,
    COALESCE(s.total_store_sales, 0) AS total_store_sales,
    COALESCE(s.avg_sales_price, 0) AS avg_sales_price,
    CASE 
        WHEN rs.total_net_profit > 1000 THEN 'High Value'
        WHEN rs.total_net_profit > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    RankedSales rs
LEFT JOIN 
    StoreSalesData s ON rs.c_customer_sk = s.ss_item_sk
WHERE 
    rs.rank <= 10
ORDER BY 
    rs.total_net_profit DESC;
