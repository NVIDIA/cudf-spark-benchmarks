
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rank_return,
        AVG(sr_return_amt_inc_tax) OVER (PARTITION BY sr_customer_sk) AS avg_return_amt,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_customer_sk) AS total_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
ReturnDetails AS (
    SELECT 
        r.sr_item_sk,
        r.sr_customer_sk,
        r.sr_return_quantity AS return_quantity,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(r.avg_return_amt, 0.00) AS avg_return_amt,
        CASE 
            WHEN r.rank_return = 1 THEN 'Top Returner'
            ELSE 'Regular Returner'
        END AS return_category
    FROM 
        RankedReturns r
    JOIN 
        item i ON r.sr_item_sk = i.i_item_sk
    WHERE 
        r.total_return_quantity > 1
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COUNT(ws.ws_order_number) AS sales_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    rd.i_item_desc,
    rd.return_category,
    rd.return_quantity,
    rd.avg_return_amt,
    COALESCE(si.total_sales_value, 0) AS total_sales_value,
    si.sales_count,
    CASE 
        WHEN rd.avg_return_amt > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profitability,
    CASE 
        WHEN rd.return_category = 'Top Returner' AND COALESCE(si.total_sales_value, 0) = 0 THEN NULL 
        ELSE 'N/A'
    END AS special_case_flag
FROM 
    ReturnDetails rd
LEFT JOIN 
    SalesInfo si ON rd.sr_item_sk = si.ws_item_sk
WHERE 
    (rd.return_category = 'Top Returner' OR si.sales_count > 5)
ORDER BY 
    rd.return_quantity DESC, 
    total_sales_value DESC;
