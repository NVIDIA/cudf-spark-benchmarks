
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                FROM date_dim 
                                WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
), 
ReturnsData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
FinalReport AS (
    SELECT 
        i.i_item_id,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_sales, 0.00) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_net_loss, 0.00) AS total_net_loss,
        COALESCE(sd.total_sales, 0.00) - COALESCE(rd.total_net_loss, 0.00) AS profit_loss,
        RANK() OVER (ORDER BY (COALESCE(sd.total_sales, 0.00) - COALESCE(rd.total_net_loss, 0.00)) DESC) AS profit_rank
    FROM 
        item i
    LEFT JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        ReturnsData rd ON i.i_item_sk = rd.wr_item_sk
    WHERE 
        i.i_current_price > 20.00
    ORDER BY 
        profit_rank
    LIMIT 10
)
SELECT 
    f.i_item_id,
    f.total_quantity,
    f.total_sales,
    f.total_returns,
    f.total_net_loss,
    f.profit_loss
FROM 
    FinalReport f
WHERE 
    f.profit_loss > 0
UNION ALL
SELECT 
    'Total' AS i_item_id,
    SUM(total_quantity),
    SUM(total_sales),
    SUM(total_returns),
    SUM(total_net_loss),
    SUM(profit_loss)
FROM 
    FinalReport;
