
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),

SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),

TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(csr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.order_count,
        csr.return_count,
        (COALESCE(ss.total_sales, 0) - COALESCE(csr.total_returned_quantity, 0) * (SELECT AVG(ws_ext_sales_price) FROM web_sales)) AS net_value
    FROM 
        customer c
    LEFT JOIN CustomerReturns csr ON c.c_customer_sk = csr.cr_returning_customer_sk
    LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        (COALESCE(ss.total_sales, 0) > 1000 OR csr.return_count > 5)
),

RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY net_value DESC) AS rank
    FROM 
        TopCustomers
)

SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_returned_quantity,
    rc.total_sales,
    rc.order_count,
    rc.return_count,
    rc.net_value,
    COALESCE(NULLIF(rc.order_count, 0), 1) AS adjusted_order_count
FROM 
    RankedCustomers rc
WHERE 
    rc.rank <= 10;
