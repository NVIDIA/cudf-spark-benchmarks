WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2001)
    GROUP BY ws.ws_item_sk, ws.ws_order_number
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.total_quantity,
        rs.total_sales,
        COALESCE(NULLIF(rs.total_sales, 0), NULL) AS adjusted_sales 
    FROM RankedSales rs
    WHERE rs.sales_rank <= 3
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IS NOT NULL
      AND cd.cd_purchase_estimate > 1000
),
SalesSummary AS (
    SELECT 
        fd.ws_item_sk,
        SUM(fd.total_quantity) AS total_unknown
    FROM FilteredSales fd
    JOIN CustomerDetails cd ON cd.c_customer_sk = fd.ws_order_number
    WHERE cd.cd_gender = 'F' OR cd.cd_marital_status = 'S'
    GROUP BY fd.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_unknown, 0) AS total_sales_quantity,
    CASE 
        WHEN ss.total_unknown > 100 THEN 'High'
        WHEN ss.total_unknown BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    REPLACE(i.i_item_desc, ' ', '-') AS item_identifier
FROM item i
LEFT JOIN SalesSummary ss ON i.i_item_sk = ss.ws_item_sk
WHERE i.i_rec_start_date < cast('2002-10-01' as date)
  AND (i.i_current_price IS NOT NULL AND i.i_current_price > 50)
ORDER BY total_sales_quantity DESC, i.i_item_desc ASC
LIMIT 10;