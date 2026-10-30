WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 AND 
        dd.d_month_seq BETWEEN 1 AND 6  
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id, 
        item.i_product_name, 
        RankedSales.total_quantity, 
        RankedSales.total_net_profit
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.profit_rank <= 10  
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
)
SELECT 
    t.i_product_name, 
    t.total_quantity, 
    t.total_net_profit, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.customer_count
FROM 
    TopItems t
JOIN 
    CustomerDemographics cd ON 1=1  
ORDER BY 
    t.total_net_profit DESC;