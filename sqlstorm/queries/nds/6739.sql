
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk, i.i_product_name
),
RankedSales AS (
    SELECT
        sd.*,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_profit DESC) AS profit_rank,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_quantity DESC) AS quantity_rank
    FROM
        SalesData sd
)
SELECT
    r.ws_sold_date_sk,
    r.i_product_name,
    r.total_quantity,
    r.total_profit,
    r.avg_net_paid,
    CASE 
        WHEN r.profit_rank = 1 THEN 'Top Profit'
        ELSE 'Other'
    END AS profit_category,
    CASE 
        WHEN r.quantity_rank = 1 THEN 'Top Quantity'
        ELSE 'Other'
    END AS quantity_category
FROM
    RankedSales r
WHERE
    r.profit_rank <= 5 OR r.quantity_rank <= 5
ORDER BY
    r.ws_sold_date_sk, r.total_profit DESC;
