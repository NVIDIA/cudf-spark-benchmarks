
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2400 AND 2440
),
TotalReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        d.d_dow,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT s.ss_ticket_number) AS purchase_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE d.d_dow IN (1, 2, 3)
    GROUP BY c.c_customer_sk, d.d_dow, cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales,
        SUM(COALESCE(tr.total_return_qty, 0)) AS total_return_qty,
        SUM(COALESCE(tr.total_return_amt, 0)) AS total_return_amt
    FROM web_sales ws
    JOIN CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN TotalReturns tr ON ws.ws_item_sk = tr.sr_item_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    s.c_customer_sk,
    s.total_sales,
    s.avg_sales,
    s.total_return_qty,
    s.total_return_amt,
    CASE
        WHEN s.total_sales > 0 THEN (s.total_sales - s.total_return_amt) / s.total_sales
        ELSE NULL
    END AS net_sales_ratio,
    COUNT(DISTINCT rs.ws_order_number) AS total_order_count
FROM SalesSummary s
LEFT JOIN RankedSales rs ON s.c_customer_sk = rs.ws_item_sk
GROUP BY s.c_customer_sk, s.total_sales, s.avg_sales, s.total_return_qty, s.total_return_amt;
