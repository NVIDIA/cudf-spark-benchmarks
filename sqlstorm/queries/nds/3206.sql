WITH ItemSales AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE
        ws.ws_ship_date_sk BETWEEN 2459841 AND 2459871 
    GROUP BY
        i.i_item_sk, i.i_item_desc
),
TopItems AS (
    SELECT
        i_item_sk,
        i_item_desc,
        total_sales,
        avg_sales_price,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        ItemSales
)
SELECT
    ti.i_item_desc,
    CASE 
        WHEN iih.hd_income_band_sk IS NOT NULL THEN 'Targeted'
        ELSE 'Non-Targeted'
    END AS targeting_status,
    ti.total_sales,
    ti.avg_sales_price,
    ti.order_count
FROM
    TopItems ti
LEFT JOIN
    (SELECT DISTINCT
        h.hd_income_band_sk,
        h.hd_buy_potential,
        h.hd_dep_count
     FROM
        household_demographics h
     WHERE
        h.hd_buy_potential = 'High'
    ) iih ON ti.i_item_sk = iih.hd_income_band_sk
WHERE
    ti.sales_rank <= 10
ORDER BY
    ti.total_sales DESC