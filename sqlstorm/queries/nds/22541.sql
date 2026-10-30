
WITH popular_items AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY
        ws_item_sk
),
item_details AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand
    FROM
        item i
    LEFT JOIN
        inventory inv ON i.i_item_sk = inv.inv_item_sk AND inv.inv_date_sk = 1
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CASE
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status
        END AS marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
return_summary AS (
    SELECT
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_item_sk
)
SELECT
    i.i_item_desc AS item_description,
    i.i_current_price AS current_price,
    p.total_sold AS total_sales,
    ci.total_profit AS customer_profit,
    COALESCE(rs.total_returns, 0) AS return_count,
    CASE
        WHEN COALESCE(rs.total_return_amount, 0) > 0 THEN 'High Return'
        WHEN COALESCE(rs.total_return_amount, 0) = 0 THEN 'No Returns'
        ELSE 'Return Issue'
    END AS return_status,
    (CASE WHEN i.quantity_on_hand < 10 THEN 'Restock Needed' ELSE 'Sufficient Stock' END) AS stock_status
FROM
    item_details i
JOIN
    popular_items p ON i.i_item_sk = p.ws_item_sk
JOIN
    customer_info ci ON ci.total_profit > 500
LEFT JOIN
    return_summary rs ON i.i_item_sk = rs.sr_item_sk
WHERE
    p.rank <= 10
ORDER BY
    i.i_current_price DESC,
    p.total_sold DESC;
