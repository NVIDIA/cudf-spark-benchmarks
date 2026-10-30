WITH SalesSummary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        item.i_category AS item_category
    FROM
        web_sales ws
    JOIN item ON ws.ws_item_sk = item.i_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2459500 AND 2459565  
    GROUP BY
        ws.ws_item_sk,
        item.i_category
),
TopSellingItems AS (
    SELECT
        item_category,
        total_quantity_sold,
        total_net_paid,
        avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY item_category ORDER BY total_quantity_sold DESC) AS rank
    FROM
        SalesSummary
)

SELECT
    t.item_category,
    t.total_quantity_sold,
    t.total_net_paid,
    t.avg_sales_price
FROM
    TopSellingItems t
WHERE
    t.rank <= 5
ORDER BY
    t.item_category,
    t.total_quantity_sold DESC;