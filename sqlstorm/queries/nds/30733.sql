
WITH  SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2400 AND 2500
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN CONCAT('Income Band: ', ib.ib_lower_bound, '-', ib.ib_upper_bound)
            ELSE 'Income Band: Not Available'
        END AS income_band
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.c_email_address,
    cd.cd_gender,
    sd.ws_order_number,
    SUM(sd.ws_quantity) AS total_quantity,
    SUM(sd.ws_ext_sales_price) AS total_sales,
    AVG(sd.ws_net_profit) AS average_net_profit,
    MAX(sd.ws_quantity) AS max_quantity,
    COUNT(sd.ws_item_sk) FILTER (WHERE sd.ws_quantity > 1) AS items_above_one
FROM 
    SalesCTE AS sd
JOIN 
    CustomerDetails AS cd ON sd.ws_item_sk = cd.c_customer_sk
GROUP BY 
    cd.c_email_address, 
    cd.cd_gender, 
    sd.ws_order_number
HAVING 
    SUM(sd.ws_quantity) > 10
ORDER BY 
    total_sales DESC
LIMIT 100;
