
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
ItemSales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        COALESCE(r.total_sales, 0) AS total_sales,
        COALESCE(r.total_quantity, 0) AS total_quantity,
        i.i_current_price,
        CASE
            WHEN COALESCE(r.total_sales, 0) = 0 THEN 0
            ELSE (COALESCE(r.total_sales, 0) / NULLIF(COALESCE(r.total_quantity, 0), 0)) 
        END AS avg_price_per_item,
        CASE
            WHEN r.sales_rank <= 10 THEN 'Top Seller'
            ELSE 'Regular'
        END AS sales_category
    FROM
        item i
    LEFT JOIN RankedSales r ON i.i_item_sk = r.ws_item_sk
    WHERE
        i.i_current_price > 20
),
FrequentCustomers AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
    HAVING
        COUNT(DISTINCT ws_order_number) >= 5
),
FinalReport AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_product_name,
        i.total_sales,
        i.total_quantity,
        i.avg_price_per_item,
        i.sales_category
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN ItemSales i ON ws.ws_item_sk = i.i_item_sk
    JOIN FrequentCustomers fc ON c.c_customer_sk = fc.ws_bill_customer_sk
)

SELECT
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.i_product_name,
    f.total_sales,
    f.total_quantity,
    f.avg_price_per_item,
    f.sales_category
FROM
    FinalReport f
ORDER BY
    f.total_sales DESC, f.c_last_name;
