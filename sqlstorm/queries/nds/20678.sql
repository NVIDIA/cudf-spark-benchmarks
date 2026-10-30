
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
date_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
    HAVING 
        SUM(ws.ws_ext_sales_price) > 10000
),
item_returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ds.d_year,
        ds.total_sales,
        COALESCE(ir.total_returns, 0) AS total_returns,
        COALESCE(ir.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN ir.total_return_amount IS NULL THEN 'No Returns'
            WHEN ir.total_return_amount > ds.total_sales THEN 'High Return Risk'
            ELSE 'Normal'
        END AS return_risk
    FROM 
        customer_stats cs
    LEFT JOIN 
        date_sales ds ON cs.rank = 1 
    LEFT JOIN 
        item_returns ir ON cs.c_customer_sk = ir.cr_item_sk
)
SELECT 
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.d_year,
    a.total_sales,
    a.total_returns,
    a.total_return_amount,
    a.return_risk,
    CASE 
        WHEN a.return_risk = 'High Return Risk' THEN 'Consider promotional offers'
        ELSE 'Standard marketing approach'
    END AS marketing_strategy
FROM 
    analysis a
WHERE 
    a.total_sales > (SELECT AVG(total_sales) FROM date_sales)
ORDER BY 
    a.total_sales DESC
LIMIT 10;
