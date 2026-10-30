
WITH SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discounts,
        d_year,
        d_month_seq
    FROM
        web_sales
    JOIN
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE
        d_year BETWEEN 2020 AND 2023
    GROUP BY
        ws_item_sk, d_year, d_month_seq
),
CustomerData AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_demographics
    JOIN
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY
        cd_demo_sk, cd_gender, cd_marital_status
),
InventoryData AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM
        inventory
    GROUP BY
        inv_item_sk
)
SELECT
    sd.ws_item_sk,
    SUM(sd.total_quantity) AS total_sold,
    SUM(sd.total_sales) AS total_revenue,
    SUM(sd.total_discounts) AS total_discounts,
    cd.customer_count,
    id.total_inventory,
    (SUM(sd.total_sales) - SUM(sd.total_discounts)) / NULLIF(SUM(sd.total_quantity), 0) AS avg_price_per_item
FROM
    SalesData sd
JOIN
    CustomerData cd ON sd.ws_item_sk = cd.cd_demo_sk
JOIN
    InventoryData id ON sd.ws_item_sk = id.inv_item_sk
GROUP BY
    sd.ws_item_sk, cd.customer_count, id.total_inventory
HAVING
    SUM(sd.total_quantity) > 100
ORDER BY
    total_revenue DESC
LIMIT 50;
