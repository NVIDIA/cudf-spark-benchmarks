
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopProducts AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_profit
    FROM 
        RankedSales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.profit_rank <= 10
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_net_loss) AS total_net_loss
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_net_loss, 0) AS total_net_loss,
    tp.total_quantity,
    tp.total_profit
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON cr.wr_returning_customer_sk = c.c_customer_sk
JOIN 
    TopProducts tp ON tp.total_quantity > (
        SELECT AVG(total_quantity) FROM TopProducts
    )
WHERE 
    EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = c.c_customer_sk 
        AND ss.ss_sold_date_sk = (
            SELECT MAX(d.d_date_sk) FROM date_dim d
            WHERE d.d_date = '2002-10-01'
        )
    )
ORDER BY 
    total_profit DESC
LIMIT 50;
