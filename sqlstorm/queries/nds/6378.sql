
WITH CustomerReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighReturnCustomers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, cr.total_returns
    FROM customer c
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
),
SalesByCustomer AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_sales_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopProfitableCustomers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, sb.total_sales_profit
    FROM customer c
    JOIN SalesByCustomer sb ON c.c_customer_sk = sb.ws_bill_customer_sk
    ORDER BY sb.total_sales_profit DESC
    LIMIT 10
),
FinalReport AS (
    SELECT hrc.c_customer_id AS high_return_id, 
           hrc.c_first_name AS high_return_first_name, 
           hrc.c_last_name AS high_return_last_name,
           tpc.c_customer_id AS top_profit_id, 
           tpc.c_first_name AS top_profit_first_name,
           tpc.c_last_name AS top_profit_last_name
    FROM HighReturnCustomers hrc
    FULL OUTER JOIN TopProfitableCustomers tpc ON hrc.c_customer_id = tpc.c_customer_id
)
SELECT * FROM FinalReport;
