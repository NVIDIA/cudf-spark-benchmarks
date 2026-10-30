
WITH  Sales_CTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rank
    FROM
        web_sales
    WHERE
        ws_sales_price IS NOT NULL
),
Top_Selling_Items AS (
    SELECT
        item.i_item_sk,
        item.i_item_desc,
        SUM(sales.ws_quantity) AS total_sold
    FROM
        Sales_CTE sales
    JOIN
        item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY
        item.i_item_sk,
        item.i_item_desc
    ORDER BY
        total_sold DESC
    LIMIT 10
),
Item_Sales AS (
    SELECT
        tsi.i_item_sk,
        tsi.i_item_desc,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        Top_Selling_Items tsi
    LEFT JOIN
        web_sales ws ON tsi.i_item_sk = ws.ws_item_sk
    GROUP BY
        tsi.i_item_sk,
        tsi.i_item_desc
),
Profit_Analysis AS (
    SELECT
        ia.i_item_sk,
        ia.i_item_desc,
        ia.total_profit,
        ia.order_count,
        RANK() OVER (ORDER BY ia.total_profit DESC) AS profit_rank,
        CASE
            WHEN ia.total_profit > 1000 THEN 'High Profit'
            WHEN ia.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM
        Item_Sales ia
)
SELECT
    pa.i_item_sk,
    pa.i_item_desc,
    pa.total_profit,
    pa.order_count,
    pa.profit_rank,
    pa.profit_category,
    CASE
        WHEN pa.order_count > 50 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity
FROM
    Profit_Analysis pa
WHERE
    pa.profit_category <> 'Low Profit'
ORDER BY
    pa.profit_rank, pa.total_profit DESC;

