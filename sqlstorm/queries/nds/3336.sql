
WITH CustomerReturns AS (
    SELECT
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_item_sk
),
Promotions AS (
    SELECT
        p_item_sk,
        p_discount_active,
        COUNT(*) AS promo_count
    FROM promotion
    WHERE p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY p_item_sk, p_discount_active
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity_sold
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
ItemAnalysis AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(CR.total_returns, 0) AS total_returns,
        COALESCE(CR.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(SD.total_sales, 0) AS total_sales,
        COALESCE(SD.total_quantity_sold, 0) AS total_quantity_sold,
        P.promo_count,
        CASE 
            WHEN COALESCE(SD.total_sales, 0) > 0 THEN ROUND(COALESCE(CR.total_return_amount, 0) / COALESCE(SD.total_sales, 0), 4) * 100
            ELSE 0
        END AS return_rate_percentage
    FROM item i
    LEFT JOIN CustomerReturns CR ON i.i_item_sk = CR.sr_item_sk
    LEFT JOIN SalesData SD ON i.i_item_sk = SD.ws_item_sk
    LEFT JOIN Promotions P ON i.i_item_sk = P.p_item_sk
)
SELECT
    a.i_item_sk,
    a.i_item_desc,
    a.total_returns,
    a.total_return_quantity,
    a.total_sales,
    a.total_quantity_sold,
    a.promo_count,
    a.return_rate_percentage
FROM ItemAnalysis a
LEFT JOIN customer c ON c.c_current_cdemo_sk IN (
    SELECT cd_demo_sk
    FROM customer_demographics
    WHERE cd_gender = 'F' AND cd_marital_status = 'M'
)
WHERE a.return_rate_percentage > 10
ORDER BY a.return_rate_percentage DESC;
