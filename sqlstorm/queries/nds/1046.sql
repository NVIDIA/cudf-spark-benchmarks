
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws.ws_item_sk
),
TopSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        i.i_item_desc,
        COALESCE(w.w_warehouse_name, 'N/A') AS warehouse_name
    FROM
        SalesData sd
    JOIN
        item i ON sd.ws_item_sk = i.i_item_sk
    LEFT JOIN
        inventory inv ON inv.inv_item_sk = sd.ws_item_sk
    LEFT JOIN
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        sd.rn = 1
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COUNT(DISTINCT ts.ws_item_sk) AS items_purchased,
    SUM(ts.total_sales) AS total_spent,
    AVG(ts.total_quantity) AS avg_quantity_per_item,
    MAX(ts.total_sales) AS max_single_item_sales,
    MIN(ts.total_sales) AS min_single_item_sales
FROM
    customer c
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    TopSales ts ON ws.ws_item_sk = ts.ws_item_sk
WHERE
    c.c_birth_year IS NOT NULL
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_last_name LIKE 'S%')
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name
HAVING
    SUM(ts.total_sales) > 1000
ORDER BY
    total_spent DESC
LIMIT 10;
