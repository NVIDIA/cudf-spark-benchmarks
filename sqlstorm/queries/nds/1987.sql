
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_customer_sk, 
        sr_reason_sk, 
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY 
        sr_returned_date_sk, 
        sr_item_sk, 
        sr_customer_sk, 
        sr_reason_sk
),
DailySales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount
    FROM web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(DailySales.total_quantity_sold, 0) AS sold_quantity,
        COALESCE(CustomerReturns.total_return_quantity, 0) AS return_quantity,
        COALESCE(DailySales.total_sales_amount, 0) AS sales_amount,
        COALESCE(CustomerReturns.total_return_amount, 0) AS return_amount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(DailySales.total_sales_amount, 0) - COALESCE(CustomerReturns.total_return_amount, 0) DESC) AS rank
    FROM item
    LEFT JOIN DailySales ON item.i_item_sk = DailySales.ws_item_sk
    LEFT JOIN CustomerReturns ON item.i_item_sk = CustomerReturns.sr_item_sk
)
SELECT 
    TopItems.i_item_id, 
    TopItems.i_item_desc,
    TopItems.sold_quantity,
    TopItems.return_quantity,
    TopItems.sales_amount,
    TopItems.return_amount
FROM 
    TopItems
WHERE 
    TopItems.rank <= 10
    AND (TopItems.sold_quantity > 10 OR TopItems.return_quantity < 5)
ORDER BY 
    TopItems.sales_amount DESC;
