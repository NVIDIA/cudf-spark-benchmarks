
WITH  SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_sales_price) > 1000
),
ReturnsData AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_order_number) AS return_count,
        SUM(wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
FilterItems AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_product_name, 
        COALESCE(sd.total_sales, 0) AS sales_amount,
        COALESCE(rd.return_count, 0) AS total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_value, 0)) AS net_sales
    FROM 
        item i
    LEFT JOIN 
        SalesData sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN 
        ReturnsData rd ON i.i_item_sk = rd.wr_item_sk
)
SELECT 
    fi.i_item_id,
    fi.i_product_name,
    fi.sales_amount,
    fi.total_returns,
    fi.net_sales,
    CASE 
        WHEN fi.net_sales < 0 THEN 'Underperforming'
        WHEN fi.net_sales BETWEEN 0 AND 100 THEN 'Average'
        ELSE 'High Performer'
    END AS performance_status,
    CURRENT_DATE AS report_date
FROM 
    FilterItems fi
WHERE 
    fi.net_sales IS NOT NULL
ORDER BY 
    fi.net_sales DESC
LIMIT 10;
