
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnPercentage AS (
    SELECT 
        COALESCE(cr.sr_customer_sk, cs.ws_bill_customer_sk) AS customer_sk,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cs.total_sales_quantity, 0) AS total_sales_quantity,
        CASE 
            WHEN COALESCE(cs.total_sales_quantity, 0) > 0 THEN 
                ROUND((COALESCE(cr.total_returned_quantity, 0) * 100.0) / cs.total_sales_quantity, 2)
            ELSE 
                0
        END AS return_percentage
    FROM CustomerReturns cr
    FULL OUTER JOIN CustomerSales cs ON cr.sr_customer_sk = cs.ws_bill_customer_sk
),
TopReturnCustomers AS (
    SELECT 
        customer_sk,
        return_percentage
    FROM ReturnPercentage
    WHERE return_percentage > 0
    ORDER BY return_percentage DESC
    LIMIT 10
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    tr.return_percentage,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM TopReturnCustomers tr
JOIN customer c ON tr.customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY tr.return_percentage DESC;
