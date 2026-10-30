
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_ship_mode_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
SalesSummary AS (
    SELECT
        d.d_year,
        item.i_item_id,
        SUM(CASE WHEN rs.rank = 1 THEN rs.ws_quantity ELSE 0 END) AS latest_quantity,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM RankedSales rs
    JOIN item ON item.i_item_sk = rs.ws_item_sk
    JOIN date_dim d ON d.d_date_sk = rs.ws_sold_date_sk
    GROUP BY d.d_year, item.i_item_id
),
StateSales AS (
    SELECT
        ca_state,
        SUM(ss.total_sales) AS sales_by_state,
        ss.i_item_id
    FROM customer_address
    JOIN customer ON customer.c_current_addr_sk = ca_address_sk
    JOIN SalesSummary ss ON ss.i_item_id = customer.c_customer_id
    GROUP BY ca_state, ss.i_item_id
)
SELECT
    ss.d_year,
    ss.i_item_id,
    ss.total_sales,
    s.sales_by_state
FROM SalesSummary ss
LEFT JOIN StateSales s ON s.i_item_id = ss.i_item_id
WHERE ss.total_sales > 0
ORDER BY ss.total_sales DESC
LIMIT 10;
