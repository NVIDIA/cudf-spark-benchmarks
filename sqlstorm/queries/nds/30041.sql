
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS order_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_qty,
        SUM(wr_return_amt) AS total_returned_amt
    FROM web_returns 
    GROUP BY wr_item_sk
),
HighValueItems AS (
    SELECT
        i_item_sk,
        i_current_price,
        COALESCE(total_returned_qty, 0) AS total_returned_qty,
        COALESCE(total_returned_amt, 0) AS total_returned_amt
    FROM item
    LEFT JOIN CustomerReturns ON item.i_item_sk = CustomerReturns.wr_item_sk
    WHERE i_current_price > (SELECT AVG(i_current_price) FROM item)
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(s.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT s.ws_order_number) AS number_of_orders
    FROM web_sales s
    JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    WHERE s.ws_item_sk IN (SELECT i_item_sk FROM HighValueItems)
    GROUP BY c.c_customer_id
)
SELECT 
    ss.c_customer_id,
    ss.total_sales,
    ss.number_of_orders,
    RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
    'Estimated Value' AS estimation
FROM SalesSummary ss
WHERE ss.total_sales > (SELECT AVG(total_sales) FROM SalesSummary)
ORDER BY ss.total_sales DESC
LIMIT 10;
