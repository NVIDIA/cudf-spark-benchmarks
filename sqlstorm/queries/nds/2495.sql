
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_net_paid
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
    GROUP BY 
        sd.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_net_paid,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN COALESCE(cr.return_count, 0) > 0 THEN 'High'
        ELSE 'Low'
    END AS return_status,
    CASE 
        WHEN ts.total_net_paid >= 1000 THEN 'High Value'
        ELSE 'Standard'
    END AS sale_value
FROM 
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
WHERE 
    ts.total_quantity IS NOT NULL
ORDER BY 
    ts.total_net_paid DESC
LIMIT 50;
