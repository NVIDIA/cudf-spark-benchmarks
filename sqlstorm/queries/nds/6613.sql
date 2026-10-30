
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        rs.total_quantity_sold,
        rs.total_sales
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.rank <= 10
),
CustomerSegment AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ts.total_sales) AS total_sales_by_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN TopSellingItems ts ON ts.total_sales > 0
    GROUP BY cd.cd_gender
)
SELECT 
    cs.cd_gender,
    cs.customer_count,
    cs.total_sales_by_gender,
    CAST(cs.total_sales_by_gender / SUM(cs.total_sales_by_gender) OVER () * 100 AS DECIMAL(5, 2)) AS sales_percentage
FROM CustomerSegment cs
ORDER BY cs.total_sales_by_gender DESC;
