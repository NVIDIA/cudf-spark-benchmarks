
WITH sales_data AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns
    FROM
        item i
    LEFT JOIN
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY
        i.i_item_sk, i.i_item_id, i.i_product_name, i.i_current_price
),
sales_rank AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        id.i_product_name,
        id.i_current_price,
        id.total_returns,
        RANK() OVER (PARTITION BY id.i_item_id ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        sales_data sd
    JOIN
        item_details id ON sd.ws_item_sk = id.i_item_sk
)

SELECT
    sr.sales_rank,
    sr.i_product_name,
    sr.total_quantity,
    sr.total_sales,
    sr.i_current_price,
    sr.total_returns,
    CASE
        WHEN sr.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    (sr.total_sales - sr.total_returns * sr.i_current_price) AS net_sales
FROM
    sales_rank sr
WHERE
    sr.sales_rank <= 10
ORDER BY
    sr.sales_rank;
