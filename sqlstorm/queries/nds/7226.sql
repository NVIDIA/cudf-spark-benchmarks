
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
    WHERE 
        dd.d_year = 2023 
        AND it.i_category = 'Beverages'
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.wr_item_sk
),
CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.avg_net_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_net_loss, 0) AS total_net_loss
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    cd.total_quantity,
    cd.total_sales,
    cd.avg_net_profit,
    cd.total_returns,
    cd.total_net_loss,
    (cd.total_sales - cd.total_net_loss) AS net_revenue
FROM 
    CombinedData cd
JOIN 
    item it ON cd.ws_item_sk = it.i_item_sk
ORDER BY 
    net_revenue DESC 
LIMIT 10;
