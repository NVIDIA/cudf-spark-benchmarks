
WITH  SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
TopCustomers AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM
        customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
),
SalesSummary AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT s.ws_order_number) AS total_orders,
        SUM(s.ws_ext_sales_price) AS total_sales,
        AVG(CASE WHEN s.ws_quantity IS NOT NULL THEN s.ws_quantity END) AS avg_quantity,
        SUM(CASE WHEN s.ws_quantity > 0 THEN s.ws_quantity ELSE 0 END) AS positive_sales_quantity
    FROM
        web_sales s
    JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY
        c.c_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    ss.total_orders,
    ss.total_sales,
    ss.avg_quantity,
    (ss.positive_sales_quantity - tc.total_returns) AS net_positive_sales,
    RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
    CASE 
        WHEN tc.total_returns > 0 THEN 'Yes'
        ELSE 'No'
    END AS returned_customer
FROM
    TopCustomers tc
LEFT JOIN SalesSummary ss ON tc.c_customer_sk = ss.c_customer_sk
ORDER BY
    net_positive_sales DESC, sales_rank
LIMIT 100;
