
WITH SaleDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        i.i_product_name,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_date_sk,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
),

CustomerReturns AS (
    SELECT 
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr_returning_customer_sk
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other' 
        END AS marital_status
    FROM 
        customer_demographics cd
)

SELECT 
    c.c_customer_id,
    SUM(sd.ws_net_profit) AS total_profit,
    SUM(COALESCE(cr.wr_return_amt, 0)) AS total_return_amount,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    COUNT(DISTINCT cr.wr_order_number) AS total_returns,
    ROUND(((SUM(sd.ws_net_profit) - SUM(COALESCE(cr.wr_return_amt, 0))) / NULLIF(SUM(sd.ws_net_profit), 0)) * 100, 2) AS profit_margin_percentage,
    cd.cd_gender,
    cd.marital_status
FROM 
    customer c
LEFT JOIN 
    SaleDetails sd ON c.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.marital_status
HAVING 
    SUM(sd.ws_net_profit) > 0
ORDER BY 
    total_profit DESC;
