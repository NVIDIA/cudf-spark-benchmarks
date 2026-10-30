
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk, ws_order_number
),
AggregatedReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
),
FilteredItems AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(ar.total_returned, 0) AS total_returned,
        COALESCE(ar.total_return_amount, 0) AS total_return_amount,
        COALESCE(rs.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(rs.total_sales, 0) > 0 
            THEN (COALESCE(ar.total_returned, 0) * 1.0 / COALESCE(rs.total_sales, 0)) * 100 
            ELSE NULL 
        END AS return_percentage
    FROM 
        item i
    LEFT JOIN 
        AggregatedReturns ar ON i.i_item_sk = ar.wr_item_sk
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        i.i_current_price > 20.00 
        AND (rs.sales_rank = 1 OR rs.sales_rank IS NULL)
)
SELECT 
    fi.i_item_sk,
    fi.i_item_desc,
    fi.i_current_price,
    fi.total_returned,
    fi.total_return_amount,
    fi.return_percentage,
    ROW_NUMBER() OVER (ORDER BY fi.return_percentage DESC NULLS LAST) AS return_rank
FROM 
    FilteredItems fi
WHERE 
    fi.return_percentage IS NOT NULL
ORDER BY 
    return_rank
LIMIT 50;
