
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        r.r_reason_desc,
        i.i_item_sk
    FROM 
        item i
    LEFT JOIN 
        promotion p ON p.p_item_sk = i.i_item_sk
    LEFT JOIN 
        reason r ON p.p_promo_sk = r.r_reason_sk
),
TopSellingItems AS (
    SELECT 
        id.i_item_id,
        id.i_item_desc,
        rs.total_sales_price,
        rs.total_net_profit
    FROM 
        RankedSales rs
    JOIN 
        ItemDetails id ON rs.ws_item_sk = id.i_item_sk
    WHERE 
        rs.sales_rank <= 10
)

SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_sales_price,
    tsi.total_net_profit,
    CONCAT('Total sales for ', tsi.i_item_desc, ' is $', CAST(tsi.total_sales_price AS VARCHAR(255)), ' with a net profit of $', CAST(tsi.total_net_profit AS VARCHAR(255))) AS sales_summary
FROM 
    TopSellingItems tsi
ORDER BY 
    tsi.total_sales_price DESC;
