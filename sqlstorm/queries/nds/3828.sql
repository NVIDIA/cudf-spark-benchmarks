
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_return_tax) AS total_returned_tax
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
PromotionDetails AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
SalesSummary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT 
    d.d_date AS sales_date,
    COALESCE(sales.total_sold_quantity, 0) AS total_sold_quantity,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(pd.total_sales, 0) AS total_sales_from_promotion,
    SUM(sales.total_net_profit) AS total_net_profit
FROM 
    date_dim d
LEFT JOIN 
    SalesSummary sales ON d.d_date_sk = sales.ws_sold_date_sk
LEFT JOIN 
    CustomerReturns cr ON d.d_date_sk = cr.sr_returned_date_sk
LEFT JOIN 
    PromotionDetails pd ON sales.ws_item_sk = pd.p_promo_sk
WHERE 
    d.d_year = 2023
    AND (cr.total_returns IS NULL OR cr.total_returns > 0)
GROUP BY 
    d.d_date, sales.total_sold_quantity, cr.total_returns, cr.total_returned_quantity, cr.total_returned_amount, pd.total_sales
ORDER BY 
    sales_date;
