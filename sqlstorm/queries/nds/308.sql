
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        cs_net_profit,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) AS rank_profit
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(SUM(rs.cs_quantity), 0) AS total_sold,
    COALESCE(SUM(rs.cs_net_profit), 0) AS total_profit,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(SUM(rs.cs_net_profit), 0) - COALESCE(cr.total_return_amount, 0) AS final_profit
FROM 
    RankedSales rs
JOIN 
    item i ON rs.cs_item_sk = i.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON rs.cs_item_sk = cr.sr_item_sk
JOIN 
    web_sales ws ON rs.cs_item_sk = ws.ws_item_sk 
LEFT JOIN 
    CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
WHERE 
    rs.rank_profit = 1
GROUP BY 
    i.i_item_id, i.i_item_desc, cr.total_returns, cr.total_return_amount
HAVING 
    (COALESCE(SUM(rs.cs_net_profit), 0) - COALESCE(cr.total_return_amount, 0)) > 1000 
ORDER BY 
    total_profit DESC;
