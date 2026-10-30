
WITH SalesData AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_sold_date_sk,
        dd.d_date,
        DENSE_RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_paid_inc_tax DESC) AS rank_per_item
    FROM
        catalog_sales cs
    JOIN
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2022
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
    FROM
        web_returns wr
    GROUP BY
        wr.wr_item_sk
),
FinalSales AS (
    SELECT
        sd.cs_order_number,
        sd.cs_item_sk,
        sd.cs_quantity,
        sd.cs_net_paid_inc_tax,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        (sd.cs_net_paid_inc_tax - COALESCE(cr.total_returned_amount, 0)) AS net_gain_loss
    FROM
        SalesData sd
    LEFT JOIN
        CustomerReturns cr ON sd.cs_item_sk = cr.wr_item_sk
    WHERE
        sd.rank_per_item = 1
)
SELECT
    fs.cs_item_sk,
    SUM(fs.cs_quantity) AS total_sales,
    SUM(fs.net_gain_loss) AS total_net_gain_loss,
    COUNT(DISTINCT fs.cs_order_number) AS total_orders
FROM
    FinalSales fs
GROUP BY
    fs.cs_item_sk
HAVING
    SUM(fs.net_gain_loss) > 1000
ORDER BY
    total_net_gain_loss DESC
LIMIT 10;
