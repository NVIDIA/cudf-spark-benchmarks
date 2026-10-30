
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM RankedSales rs
    WHERE rs.sales_rank <= 10
),
CustomerAddressCount AS (
    SELECT
        ca.ca_address_sk,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk
),
SalesDetails AS (
    SELECT
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        cac.customer_count,
        CASE 
            WHEN cac.customer_count IS NULL THEN 'No Customers'
            ELSE CONCAT('Customers: ', cac.customer_count)
        END AS customer_info
    FROM TopItems ti
    JOIN CustomerAddressCount cac ON cac.customer_count > 0
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    sd.customer_info
FROM SalesDetails sd
WHERE sd.total_sales IS NOT NULL 
AND sd.total_quantity > (SELECT AVG(total_quantity) FROM SalesDetails)
AND sd.total_sales >= (
    SELECT MAX(total_sales) FROM SalesDetails WHERE total_quantity > 50
)
UNION ALL
SELECT 
    ti.ws_item_sk,
    NULL AS total_quantity,
    NULL AS total_sales,
    'No Sales This Period' AS customer_info
FROM TopItems ti
WHERE NOT EXISTS (
    SELECT 1 
    FROM web_sales ws 
    WHERE ws.ws_item_sk = ti.ws_item_sk
)
ORDER BY total_sales DESC NULLS LAST;
