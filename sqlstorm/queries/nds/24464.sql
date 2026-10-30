
WITH RecentSales AS (
    SELECT
        s.ss_item_sk,
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS sales_count,
        DENSE_RANK() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
    FROM
        store_sales s
    WHERE
        s.ss_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY
        s.ss_item_sk
),
CustomerReturns AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        CASE
            WHEN COUNT(sr.sr_ticket_number) = 0 THEN NULL
            ELSE SUM(sr.sr_return_amt_inc_tax) / COUNT(sr.sr_ticket_number)
        END AS avg_return_amt
    FROM
        store_returns sr
    WHERE
        sr.sr_returned_date_sk > (SELECT MAX(d.d_date_sk) - 90 FROM date_dim d)
    GROUP BY
        sr.sr_item_sk
),
AggregateData AS (
    SELECT
        rs.ss_item_sk,
        rs.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.avg_return_amt, 0) AS avg_return_amt,
        (rs.total_sales - COALESCE(cr.total_returns, 0)) AS net_sales,
        CASE
            WHEN COALESCE(cr.total_returns, 0) = 0 THEN 0
            ELSE (cr.avg_return_amt / NULLIF(rs.total_sales, 0)) * 100
        END AS return_rate_percentage
    FROM
        RecentSales rs
    LEFT JOIN
        CustomerReturns cr ON rs.ss_item_sk = cr.sr_item_sk
)
SELECT
    ad.ss_item_sk,
    ad.total_sales,
    ad.total_returns,
    ad.net_sales,
    ad.return_rate_percentage,
    CASE
        WHEN ad.return_rate_percentage > 20 THEN 'High'
        WHEN ad.return_rate_percentage BETWEEN 10 AND 20 THEN 'Moderate'
        ELSE 'Low'
    END AS return_rate_category
FROM
    AggregateData ad
WHERE
    ad.return_rate_percentage IS NOT NULL
ORDER BY
    ad.net_sales DESC
LIMIT 100;
