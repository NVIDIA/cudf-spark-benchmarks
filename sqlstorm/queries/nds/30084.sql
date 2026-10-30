
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_quantity, 
        ws_ext_sales_price,
        ws_ext_discount_amt,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 10000
), ItemSummary AS (
    SELECT 
        i_item_sk,
        i_item_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM SalesCTE
    JOIN item ON SalesCTE.ws_item_sk = item.i_item_sk
    GROUP BY i_item_sk, i_item_id
), HighPerformingItems AS (
    SELECT 
        i_item_sk,
        i_item_id,
        total_orders,
        total_sales,
        avg_sales_price
    FROM ItemSummary
    WHERE total_orders > 5 AND avg_sales_price > 100
), CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS customer_orders,
        SUM(ws_ext_sales_price) AS customer_total_sales,
        MAX(ws_sales_price) AS customer_max_price
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    hpi.i_item_id,
    hpi.total_orders,
    hpi.total_sales,
    c.c_customer_sk,
    c.customer_orders,
    c.customer_total_sales,
    CASE 
        WHEN c.customer_total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM HighPerformingItems hpi
FULL OUTER JOIN CustomerSales c ON hpi.total_orders = c.customer_orders
WHERE (hpi.total_sales > 1000 OR c.customer_orders > 10)
ORDER BY hpi.total_sales DESC, c.customer_total_sales DESC;
