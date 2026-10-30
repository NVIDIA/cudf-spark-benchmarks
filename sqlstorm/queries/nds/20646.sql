
WITH ReturnAggregates AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amt,
        COALESCE(SUM(sr_return_tax), 0) AS total_return_tax,
        sr_item_sk
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                   AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
),
SalesAggregates AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(sa.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(sa.total_net_profit, 0) AS total_net_profit,
        (COALESCE(sa.total_sales_quantity, 0) - COALESCE(ra.total_return_quantity, 0)) AS net_sales,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'Price Unavailable' 
            ELSE CASE 
                WHEN (COALESCE(sa.total_net_profit, 0) > 0) THEN 'Profitable'
                ELSE 'Unprofitable'
            END
        END AS profit_status
    FROM 
        item i
    LEFT JOIN 
        SalesAggregates sa ON i.i_item_sk = sa.ws_item_sk
    LEFT JOIN 
        ReturnAggregates ra ON i.i_item_sk = ra.sr_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_product_name,
    id.i_current_price,
    id.total_sales_quantity,
    id.total_return_quantity,
    id.total_net_profit,
    id.net_sales,
    id.profit_status,
    CASE 
        WHEN id.net_sales = 0 THEN 'No Sales' 
        ELSE CASE 
            WHEN id.net_sales < 100 THEN 'Low Sales'
            WHEN id.net_sales BETWEEN 100 AND 500 THEN 'Medium Sales'
            ELSE 'High Sales'
        END
    END AS sales_category
FROM 
    ItemDetails id
WHERE 
    id.profit_status = 'Profitable'
ORDER BY 
    id.i_current_price DESC, 
    id.total_sales_quantity ASC
LIMIT 10;
