
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
),
HighProfitItems AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.rn <= 5 
    GROUP BY 
        r.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        hp.total_net_profit,
        CASE
            WHEN hp.total_net_profit IS NULL THEN 'No Profit'
            WHEN hp.total_net_profit > 1000 THEN 'High Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        item i
    LEFT JOIN 
        HighProfitItems hp ON i.i_item_sk = hp.ws_item_sk
),
SalesData AS (
    SELECT 
        d.d_year,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(wr.wr_return_amt, 0)) AS total_returned_amount
    FROM 
        date_dim d
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_returns sr ON d.d_date_sk = sr.sr_returned_date_sk
    LEFT JOIN 
        web_returns wr ON d.d_date_sk = wr.wr_returned_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    id.profit_category,
    sd.d_year,
    sd.total_sales,
    sd.total_returns,
    sd.total_returned_amount,
    (sd.total_sales - sd.total_returned_amount) AS net_revenue
FROM 
    ItemDetails id
JOIN 
    SalesData sd ON sd.total_sales > 0
WHERE 
    (id.profit_category = 'High Profit' OR id.profit_category = 'Low Profit')
ORDER BY 
    sd.d_year DESC, net_revenue DESC
LIMIT 10;
