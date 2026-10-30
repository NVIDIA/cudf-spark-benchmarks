
WITH  Sales_CTE AS (
    SELECT 
        ss_item_sk, 
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_item_sk
),
Top_Sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_sales,
        sales.total_orders
    FROM Sales_CTE sales
    JOIN item ON sales.ss_item_sk = item.i_item_sk
    WHERE sales.sales_rank <= 5
),
Customer_Purchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS purchase_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sales_price IS NOT NULL
    GROUP BY c.c_customer_id
),
Ranking_Customers AS (
    SELECT 
        customer.c_customer_id,
        customer.total_profit,
        customer.purchase_count,
        DENSE_RANK() OVER (ORDER BY customer.total_profit DESC) AS profit_rank
    FROM Customer_Purchases customer
),
Filtered_Customers AS (
    SELECT
        rc.c_customer_id,
        rc.total_profit,
        rc.purchase_count
    FROM Ranking_Customers rc
    WHERE rc.profit_rank <= 10
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    fc.c_customer_id,
    fc.total_profit,
    fc.purchase_count,
    COALESCE(NULLIF(ts.total_sales, 0), 1) AS adjusted_sales,
    ROUND(fc.total_profit / NULLIF(ts.total_sales, 0), 2) AS profit_per_sales
FROM Top_Sales ts
FULL OUTER JOIN Filtered_Customers fc ON 1=1
WHERE (ts.total_sales > 1000 OR fc.total_profit > 100)
ORDER BY profit_per_sales DESC;
