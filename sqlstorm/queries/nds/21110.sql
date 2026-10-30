
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS rn,
        COALESCE(NULLIF(ws.ws_ship_date_sk, 0), NULL) AS ship_date,
        CASE
            WHEN ws.ws_quantity > 0 THEN 'Sold'
            ELSE 'Unsold'
        END AS sale_status
    FROM web_sales ws
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sales_price IS NOT NULL
      AND i.i_current_price BETWEEN 10 AND 100
      AND (ws.ws_ship_mode_sk IN (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type LIKE '%Express%'))
),
FilteredSales AS (
    SELECT
        rs.ws_item_sk,
        COUNT(*) AS total_sales,
        AVG(rs.cumulative_net_profit) AS avg_cumulative_net_profit
    FROM RankedSales rs
    WHERE rs.rn <= 5
      AND rs.sale_status = 'Sold'
    GROUP BY rs.ws_item_sk
),
IncomeBandSales AS (
    SELECT
        h.hd_income_band_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales
    FROM household_demographics h
    JOIN catalog_sales cs ON h.hd_demo_sk = cs.cs_bill_cdemo_sk
    WHERE h.hd_buy_potential IS NOT NULL
    GROUP BY h.hd_income_band_sk
)
SELECT
    fs.ws_item_sk,
    fs.total_sales,
    fs.avg_cumulative_net_profit,
    ibs.total_catalog_sales,
    (CASE
        WHEN fs.total_sales IS NULL THEN 'N/A'
        ELSE CAST(fs.total_sales AS VARCHAR(10))
    END) AS total_sales_string,
    (CASE
        WHEN ibs.total_catalog_sales IS NULL THEN 'No Catalog Sales'
        WHEN ibs.total_catalog_sales > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END) AS catalog_sales_volume
FROM FilteredSales fs
FULL OUTER JOIN IncomeBandSales ibs ON fs.ws_item_sk = ibs.hd_income_band_sk
WHERE (fs.total_sales IS NOT NULL OR ibs.total_catalog_sales IS NOT NULL)
  AND (fs.avg_cumulative_net_profit > 1000 OR ibs.total_catalog_sales IS NOT NULL)
ORDER BY fs.ws_item_sk DESC NULLS LAST, ibs.total_catalog_sales ASC;
