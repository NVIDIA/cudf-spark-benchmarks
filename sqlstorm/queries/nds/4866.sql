
WITH SalesSummary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS item_rank
    FROM 
        catalog_sales AS cs
    WHERE 
        cs.cs_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_moy IN (6, 7)
        )
    GROUP BY 
        cs.cs_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        ss.total_quantity,
        ss.total_profit,
        ss.avg_sales_price,
        ss.item_rank
    FROM 
        SalesSummary ss
    JOIN 
        item ON ss.cs_item_sk = item.i_item_sk
    WHERE 
        ss.item_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr.sr_returned_date_sk,
        COUNT(DISTINCT sr.sr_customer_sk) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_tax) AS total_return_tax
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023 AND d.d_moy = 6)
    GROUP BY 
        sr.sr_returned_date_sk
)
SELECT 
    ti.i_item_id AS item_id,
    ti.i_item_desc AS item_desc,
    ti.total_quantity,
    ti.total_profit,
    ti.avg_sales_price,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COALESCE(cr.total_return_tax, 0) AS total_return_tax
FROM 
    TopItems ti
LEFT JOIN 
    CustomerReturns cr ON cr.sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
ORDER BY 
    ti.total_profit DESC, ti.i_item_id;
