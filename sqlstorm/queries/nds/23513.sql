
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        ws.ws_item_sk, ws.ws_order_number
),
HighVolumeReturns AS (
    SELECT
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
    GROUP BY
        sr_item_sk
    HAVING
        COUNT(sr_ticket_number) > 5
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Mid'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            ELSE 'High'
        END AS purchase_band
    FROM
        customer_demographics cd
    WHERE
        cd.cd_credit_rating IS NOT NULL
)
SELECT
    rng.ws_item_sk,
    COUNT(DISTINCT rng.ws_order_number) AS sales_count,
    MAX(returns.return_count) AS total_returns,
    SUM(CASE WHEN demo.purchase_band = 'Low' THEN 1 ELSE 0 END) AS low_band_customers,
    SUM(CASE WHEN demo.purchase_band = 'Mid' THEN 1 ELSE 0 END) AS mid_band_customers,
    SUM(CASE WHEN demo.purchase_band = 'High' THEN 1 ELSE 0 END) AS high_band_customers
FROM
    RankedSales rng
LEFT JOIN HighVolumeReturns returns ON rng.ws_item_sk = returns.sr_item_sk
JOIN CustomerDemographics demo ON rng.ws_order_number = demo.cd_demo_sk
WHERE
    rng.rank = 1
GROUP BY
    rng.ws_item_sk
HAVING
    MAX(returns.return_count) IS NULL OR MAX(returns.total_return_amt) > 1000
ORDER BY
    sales_count DESC, low_band_customers DESC;
