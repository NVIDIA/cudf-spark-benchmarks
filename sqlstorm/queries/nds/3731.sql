
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
),
SalesStats AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue,
        AVG(ws_sales_price) AS avg_sale_price
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
    GROUP BY 
        ws_item_sk
),
SalesWithReturns AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales,
        ss.total_revenue,
        ss.avg_sale_price,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount
    FROM 
        SalesStats ss
    LEFT JOIN 
        store_returns sr ON ss.ws_item_sk = sr.sr_item_sk
    GROUP BY 
        ss.ws_item_sk, ss.total_sales, ss.total_revenue, ss.avg_sale_price
),
FinalResults AS (
    SELECT 
        sw.ws_item_sk,
        sw.total_sales,
        sw.total_revenue,
        sw.avg_sale_price,
        sw.total_returns,
        sw.total_return_amount,
        (sw.total_revenue - sw.total_return_amount) AS net_revenue,
        (CAST(sw.total_returns AS DECIMAL) / NULLIF(sw.total_sales, 0)) * 100 AS return_rate
    FROM 
        SalesWithReturns sw
    JOIN 
        RankedSales rs ON sw.ws_item_sk = rs.ws_item_sk
    WHERE 
        rs.price_rank = 1
)
SELECT 
    fi.ws_item_sk,
    fi.total_sales,
    fi.total_revenue,
    fi.avg_sale_price,
    fi.total_returns,
    fi.total_return_amount,
    fi.net_revenue,
    fi.return_rate
FROM 
    FinalResults fi
WHERE 
    fi.return_rate < 10
ORDER BY 
    fi.net_revenue DESC;
