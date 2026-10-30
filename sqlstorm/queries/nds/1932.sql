WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1990
        AND c.c_current_addr_sk IS NOT NULL
),
AggregatedReturns AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM
        web_returns wr
    WHERE
        wr.wr_returned_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2000 AND d_moy IN (6, 7)
        )
    GROUP BY
        wr.wr_item_sk
)
SELECT
    ir.i_item_id,
    ir.i_product_name,
    COALESCE(sales.total_quantity, 0) AS total_sales_quantity,
    COALESCE(sales.total_net_profit, 0) AS total_net_profit,
    COALESCE(returns.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(returns.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(returns.total_return_quantity, 0) > 0 THEN 'High Risk'
        ELSE 'Stable'
    END AS risk_level
FROM
    item ir
LEFT JOIN (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM
        RankedSales rs
    WHERE
        rs.rank = 1
    GROUP BY
        rs.ws_item_sk
) sales ON ir.i_item_sk = sales.ws_item_sk
LEFT JOIN AggregatedReturns returns ON ir.i_item_sk = returns.wr_item_sk
WHERE
    ir.i_rec_start_date <= cast('2002-10-01' as date)
ORDER BY
    total_net_profit DESC
LIMIT 50;