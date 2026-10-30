
WITH RankedSales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS rank_sales
    FROM
        catalog_sales cs
    JOIN
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND i.i_current_price > 50.00
),
TotalReturns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity,
        SUM(cr.cr_return_amount) AS total_returned_amount
    FROM
        catalog_returns cr
    JOIN
        item i ON cr.cr_item_sk = i.i_item_sk
    WHERE
        i.i_current_price > 50.00
    GROUP BY
        cr.cr_item_sk
),
FinalResults AS (
    SELECT
        rs.cs_order_number,
        rs.cs_item_sk,
        rs.cs_quantity,
        rs.cs_sales_price,
        rs.cs_ext_sales_price,
        rs.cs_net_profit,
        tr.total_returned_quantity,
        tr.total_returned_amount
    FROM
        RankedSales rs
    LEFT JOIN
        TotalReturns tr ON rs.cs_item_sk = tr.cr_item_sk
)
SELECT
    item.i_item_id,
    COUNT(fr.cs_order_number) AS number_of_orders,
    SUM(fr.cs_quantity) AS total_quantity,
    SUM(fr.total_returned_quantity) AS total_returned,
    SUM(fr.cs_net_profit) AS total_profit,
    SUM(fr.total_returned_amount) AS total_returned_amount
FROM
    FinalResults fr
JOIN
    item item ON fr.cs_item_sk = item.i_item_sk
GROUP BY
    item.i_item_id
HAVING
    SUM(fr.total_returned_quantity) > 0
ORDER BY
    total_profit DESC
LIMIT 10;
