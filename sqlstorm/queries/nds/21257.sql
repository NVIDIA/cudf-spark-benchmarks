
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(ws.ws_ext_sales_price, 0) AS ext_sales_price,
        CASE 
            WHEN ws.ws_quantity > 0 THEN ROUND((ws.ws_sales_price - ws.ws_ext_discount_amt) / NULLIF(ws.ws_quantity, 0), 2)
            ELSE NULL 
        END AS avg_price_per_unit
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING
        SUM(ws.ws_net_paid) > 500
),
ItemSummary AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_units_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_sk, i.i_product_name
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    isum.total_sales,
    isum.total_units_sold,
    CASE 
        WHEN isum.total_sales IS NULL THEN 'No Sales'
        WHEN isum.avg_sales_price > 100 THEN 'High Value Item'
        ELSE 'Standard Item'
    END AS item_value_category,
    rs.ws_order_number,
    rs.price_rank,
    rs.avg_price_per_unit
FROM
    HighValueCustomers hvc
LEFT JOIN ItemSummary isum ON hvc.c_customer_sk = isum.i_item_sk
LEFT JOIN RankedSales rs ON rs.ws_item_sk = isum.i_item_sk
WHERE
    (rs.avg_price_per_unit IS NOT NULL OR isum.total_sales IS NOT NULL)
    AND (hvc.total_spent * 1.25) > (SELECT MAX(total_spent * 0.75) FROM HighValueCustomers)
ORDER BY
    hvc.total_spent DESC, isum.total_sales DESC
LIMIT 100;
