
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(sd.total_quantity) AS total_quantity_sold,
    SUM(sd.total_net_profit) AS total_net_profit,
    AVG(cd.total_orders) AS avg_orders_per_customer
FROM 
    CustomerData AS cd
LEFT JOIN 
    SalesData AS sd ON sd.ws_item_sk IN (
        SELECT i.i_item_sk
        FROM item AS i
        WHERE i.i_current_price BETWEEN 10 AND 100
    )
LEFT JOIN 
    income_band AS ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    sd.profit_rank <= 5
GROUP BY 
    cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    total_net_profit DESC;
