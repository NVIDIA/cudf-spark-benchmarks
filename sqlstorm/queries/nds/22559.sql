
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        i.i_item_desc
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amount 
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        ti.i_item_desc,
        ti.total_quantity,
        ti.total_sales,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(cr.return_count, 0) > 0 THEN 'Returned Items' 
            ELSE 'Non-Returned Items' 
        END AS return_status
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerReturns cr ON ti.ws_item_sk = cr.sr_item_sk
)
SELECT 
    f.i_item_desc,
    f.total_quantity,
    f.total_sales,
    f.return_count,
    f.total_return_amount,
    f.return_status,
    CASE 
        WHEN f.total_sales = 0 THEN NULL
        ELSE ROUND((f.total_return_amount / f.total_sales) * 100, 2)
    END AS return_percentage
FROM 
    FinalReport f
ORDER BY 
    f.total_sales DESC
LIMIT 50;
