WITH  Customer_Sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(COALESCE(ss.ss_net_paid, 0)) AS total_sales,
           COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
           RANK() OVER (ORDER BY SUM(COALESCE(ss.ss_net_paid, 0)) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
High_Value_Customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, total_sales, total_transactions
    FROM Customer_Sales
    WHERE total_sales > 1000
),
Recent_Transactions AS (
    SELECT ss.ss_customer_sk, ss.ss_item_sk, ss.ss_net_profit, d.d_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= cast('2002-10-01' as date) - INTERVAL '30 days'
),
Top_Items AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity_sold,
           RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM web_sales ws
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sales_price > 10
    GROUP BY ws.ws_item_sk
)
SELECT 
    hv.c_first_name, 
    hv.c_last_name, 
    hv.total_sales,
    COALESCE(SUM(rt.ss_net_profit), 0) AS recent_net_profit,
    ti.total_quantity_sold
FROM High_Value_Customers hv
LEFT JOIN Recent_Transactions rt ON hv.c_customer_sk = rt.ss_customer_sk
LEFT JOIN Top_Items ti ON rt.ss_item_sk = ti.ws_item_sk
WHERE hv.total_transactions > 5
GROUP BY hv.c_customer_sk, hv.c_first_name, hv.c_last_name, hv.total_sales, ti.total_quantity_sold
ORDER BY hv.total_sales DESC, recent_net_profit DESC
LIMIT 10;