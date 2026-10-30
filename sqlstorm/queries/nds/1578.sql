
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
CustomerReturnSummary AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
JoinedSalesReturns AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(rs.ws_quantity, 0) AS quantity_sold,
        COALESCE(crs.total_returns, 0) AS total_returns,
        COALESCE(crs.total_return_amount, 0) AS total_return_amount,
        COALESCE(crs.total_return_quantity, 0) AS total_return_quantity,
        SUM(ws_ext_sales_price) AS total_sales_value
    FROM customer cs
    LEFT JOIN RankedSales rs ON cs.c_customer_sk = rs.ws_bill_customer_sk AND rs.sales_rank = 1
    LEFT JOIN CustomerReturnSummary crs ON cs.c_customer_sk = crs.sr_customer_sk
    GROUP BY cs.c_customer_id, rs.ws_quantity, crs.total_returns, crs.total_return_amount, crs.total_return_quantity
)
SELECT 
    jcs.c_customer_id,
    jcs.quantity_sold,
    jcs.total_returns,
    jcs.total_return_amount,
    jcs.total_return_quantity,
    jcs.total_sales_value,
    CASE 
        WHEN jcs.total_sales_value > 1000 THEN 'High Value'
        WHEN jcs.total_sales_value > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM JoinedSalesReturns jcs
WHERE jcs.quantity_sold > 0
ORDER BY jcs.total_sales_value DESC
LIMIT 100;
