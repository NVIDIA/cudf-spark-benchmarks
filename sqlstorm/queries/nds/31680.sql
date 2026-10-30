
WITH  CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    HAVING SUM(wr_return_quantity) > 0
),
HighlyActiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(w.ws_order_number) AS order_count,
        SUM(w.ws_ext_sales_price) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(w.ws_ext_sales_price) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING COUNT(w.ws_order_number) > 5
),
ReturnedItems AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_returned_quantity
    FROM web_returns
    GROUP BY wr_item_sk
),
TopReturnedItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        r.total_returned_quantity
    FROM item i
    JOIN ReturnedItems r ON i.i_item_sk = r.wr_item_sk
    ORDER BY r.total_returned_quantity DESC
    LIMIT 10
)
SELECT 
    cac.c_customer_sk,
    cac.c_first_name,
    cac.c_last_name,
    cac.order_count,
    cac.total_spent,
    tai.i_item_id,
    tai.i_product_name,
    tai.total_returned_quantity
FROM HighlyActiveCustomers cac
LEFT JOIN TopReturnedItems tai ON cac.c_customer_sk IN (SELECT wr_returning_customer_sk FROM CustomerReturns)
WHERE cac.gender_rank <= 5
ORDER BY cac.total_spent DESC, tai.total_returned_quantity DESC;
