
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales AS ws
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        d.d_year = 2023
        AND i.i_current_price BETWEEN 10 AND 100
    GROUP BY
        ws.ws_item_sk
),
RankedSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_revenue,
        sd.total_orders,
        RANK() OVER (ORDER BY sd.total_revenue DESC) AS revenue_rank
    FROM
        SalesData AS sd
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity,
    rs.total_revenue,
    rs.total_orders,
    rs.revenue_rank
FROM
    RankedSales AS rs
JOIN
    item AS i ON rs.ws_item_sk = i.i_item_sk
WHERE
    rs.revenue_rank <= 10
ORDER BY
    rs.total_revenue DESC;
