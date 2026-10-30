
WITH  SalesCTE AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_order_number) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT
        ws_order_number,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM
        SalesCTE
    GROUP BY
        ws_order_number
),
CustomerSales AS (
    SELECT
        c.c_customer_id,
        ts.total_sales,
        cd.cd_gender,
        cd.cd_marital_status
    FROM
        customer c
    JOIN
        TotalSales ts ON c.c_customer_sk = ts.ws_order_number
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredSales AS (
    SELECT
        cs.c_customer_id,
        cs.total_sales,
        cs.cd_gender,
        cs.cd_marital_status
    FROM
        CustomerSales cs
    WHERE
        cs.total_sales > 2000
        AND cs.cd_gender IS NOT NULL
)
SELECT
    fs.c_customer_id,
    fs.total_sales,
    fs.cd_gender,
    AVG(fs.total_sales) OVER (PARTITION BY fs.cd_gender) AS avg_sales_by_gender,
    COUNT(DISTINCT fs.cd_marital_status) AS distinct_marital_status_count
FROM
    FilteredSales fs
GROUP BY
    fs.c_customer_id,
    fs.total_sales,
    fs.cd_gender
ORDER BY
    fs.total_sales DESC
LIMIT 50;
