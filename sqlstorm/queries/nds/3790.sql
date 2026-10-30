
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
SalesSummary AS (
    SELECT 
        ds.d_year,
        SUM(r.total_net_paid) AS year_total_sales,
        COUNT(DISTINCT r.ws_item_sk) AS total_items_sold
    FROM RankedSales r
    JOIN date_dim ds ON ds.d_date_sk = r.ws_ship_date_sk
    GROUP BY ds.d_year
),
CustomerGenderDistribution AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity_sold
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cd.cd_gender
),
RecentReturns AS (
    SELECT 
        cr.cr_returning_customer_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY cr.cr_returning_customer_sk
)
SELECT 
    ss.d_year,
    ss.year_total_sales,
    ss.total_items_sold,
    gcd.cd_gender,
    gcd.customer_count,
    gcd.total_quantity_sold,
    COALESCE(rr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rr.total_return_amount, 0) AS total_return_amount
FROM SalesSummary ss
LEFT JOIN CustomerGenderDistribution gcd ON ss.year_total_sales > 0
LEFT JOIN RecentReturns rr ON gcd.customer_count > 0
ORDER BY ss.d_year DESC, gcd.cd_gender;
