
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_returned_date_sk, sr_item_sk, sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        CTE.total_returned_quantity,
        CASE 
            WHEN CTE.total_returned_quantity > 10 THEN 'High Return'
            WHEN CTE.total_returned_quantity BETWEEN 5 AND 10 THEN 'Medium Return'
            ELSE 'Low Return'
        END AS return_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerReturns CTE ON c.c_customer_sk = CTE.sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_sales_price) AS total_sales_value
    FROM web_sales
    GROUP BY ws_item_sk
),
ReturnSummary AS (
    SELECT 
        C.c_customer_sk,
        COALESCE(H.total_returned_quantity, 0) AS returned_qty,
        COALESCE(S.total_sold_quantity, 0) AS sold_qty,
        CASE 
            WHEN COALESCE(S.total_sold_quantity, 0) > 0 THEN 
                (COALESCE(H.total_returned_quantity, 0) / COALESCE(S.total_sold_quantity, 0)) * 100
            ELSE 0 
        END AS return_rate_percentage
    FROM HighValueCustomers C
    LEFT JOIN CustomerReturns H ON C.c_customer_sk = H.sr_customer_sk
    LEFT JOIN SalesData S ON H.sr_item_sk = S.ws_item_sk
)
SELECT 
    HS.c_first_name,
    HS.c_last_name,
    HS.cd_gender,
    HS.return_category,
    RS.returned_qty,
    RS.sold_qty,
    RS.return_rate_percentage
FROM ReturnSummary RS
JOIN HighValueCustomers HS ON RS.c_customer_sk = HS.c_customer_sk
ORDER BY RS.return_rate_percentage DESC, HS.c_last_name, HS.c_first_name
LIMIT 10;
