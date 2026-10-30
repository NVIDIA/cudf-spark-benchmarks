WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),

return_summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),

final_summary AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_paid,
        COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        (ss.total_net_paid - COALESCE(rs.total_return_amt, 0)) AS net_sales,
        CASE 
            WHEN COALESCE(rs.total_return_quantity, 0) = 0 THEN 0
            ELSE (COALESCE(rs.total_return_quantity, 0) / ss.total_quantity) * 100
        END AS return_percentage,
        RANK() OVER (ORDER BY (ss.total_net_paid - COALESCE(rs.total_return_amt, 0)) DESC) AS sales_rank
    FROM 
        sales_summary ss
    LEFT JOIN 
        return_summary rs ON ss.ws_item_sk = rs.wr_item_sk
)

SELECT 
    item.i_item_id,
    item.i_item_desc,
    fs.total_quantity,
    fs.total_net_paid,
    fs.total_return_quantity,
    fs.total_return_amt,
    fs.net_sales,
    fs.return_percentage
FROM 
    final_summary fs
JOIN 
    item ON fs.ws_item_sk = item.i_item_sk
WHERE 
    fs.sales_rank <= 10
    AND item.i_brand_id IN (SELECT i_brand_id FROM item WHERE i_category_id = 1)
ORDER BY 
    fs.net_sales DESC;