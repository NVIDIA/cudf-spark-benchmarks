
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 10030
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk BETWEEN 10000 AND 10030
    GROUP BY 
        wr.wr_item_sk
),
CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
        sd.total_net_profit,
        COALESCE(-rd.total_net_loss, 0) AS net_profit_after_returns
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
),
RankedItems AS (
    SELECT 
        item.i_item_id,
        cd.total_quantity_sold,
        cd.total_returned_quantity,
        cd.total_net_profit,
        cd.net_profit_after_returns,
        RANK() OVER (ORDER BY cd.net_profit_after_returns DESC) AS profit_rank
    FROM 
        CombinedData cd
    JOIN 
        item ON cd.ws_item_sk = item.i_item_sk
)
SELECT 
    ri.i_item_id AS item_id,
    ri.total_quantity_sold,
    ri.total_returned_quantity,
    ri.total_net_profit,
    ri.net_profit_after_returns,
    CASE 
        WHEN ri.net_profit_after_returns = 0 THEN 'No Profit Data'
        ELSE 'Profit Data Available'
    END AS profit_data_status
FROM 
    RankedItems ri
WHERE 
    ri.profit_rank <= 10
ORDER BY 
    ri.net_profit_after_returns DESC;
