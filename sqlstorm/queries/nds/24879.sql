
WITH  customer_ranked AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), 
return_stats AS (
    SELECT 
        it.i_item_sk,
        COUNT(sr.sr_returned_date_sk) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_value
    FROM 
        item it
    LEFT JOIN 
        store_returns sr ON it.i_item_sk = sr.sr_item_sk
    GROUP BY 
        it.i_item_sk
)
SELECT 
    cr.c_customer_id,
    ir.total_quantity_sold,
    ir.total_sales,
    rs.total_returns,
    rs.total_return_value,
    ROW_NUMBER() OVER (PARTITION BY cr.purchase_rank ORDER BY ir.total_sales DESC) AS sales_rank
FROM 
    customer_ranked cr
LEFT JOIN 
    item_sales ir ON cr.c_customer_sk = ir.ws_item_sk
LEFT JOIN 
    return_stats rs ON ir.ws_item_sk = rs.i_item_sk
WHERE 
    (rs.total_returns IS NULL OR rs.total_return_value > 0)
    AND cr.purchase_rank <= 5
    AND (cr.cd_gender = 'F' OR cr.cd_marital_status = 'S')
ORDER BY 
    cr.c_customer_id, sales_rank;
