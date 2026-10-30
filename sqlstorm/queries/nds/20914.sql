
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
),
SalesSummary AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items_sold
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
    GROUP BY 
        rs.ws_order_number
),
CustomerReturns AS (
    SELECT 
        wr.wr_order_number,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number
),
ReturnRate AS (
    SELECT 
        ss.ws_order_number,
        ss.total_sales,
        COALESCE(cr.total_returned, 0) AS total_returned,
        CASE 
            WHEN ss.total_sales > 0 THEN 
                (COALESCE(cr.total_returned, 0) / ss.total_sales) * 100 
            ELSE 0 
        END AS return_percentage
    FROM 
        SalesSummary ss
    LEFT JOIN 
        CustomerReturns cr ON ss.ws_order_number = cr.wr_order_number
),
FinalOutput AS (
    SELECT 
        rr.ws_order_number,
        rr.total_sales,
        rr.total_returned,
        rr.return_percentage,
        CASE 
            WHEN rr.return_percentage > 20 THEN 'High Returns'
            WHEN rr.return_percentage BETWEEN 10 AND 20 THEN 'Moderate Returns'
            ELSE 'Low Returns'
        END AS return_category
    FROM 
        ReturnRate rr
)
SELECT 
    fo.ws_order_number,
    fo.total_sales,
    fo.total_returned,
    fo.return_percentage,
    fo.return_category,
    CASE 
        WHEN fo.return_category = 'High Returns' AND fo.total_sales > 1000 THEN 'Investigate High Value Returns'
        ELSE 'Monitor'
    END AS action_required,
    CONCAT('Order ', fo.ws_order_number, ' has total sales of ', 
           CAST(fo.total_sales AS STRING), 
           ' with a return percentage of ', 
           CAST(fo.return_percentage AS STRING), 
           '% categorized as ', 
           fo.return_category) AS report
FROM 
    FinalOutput fo
WHERE 
    fo.return_percentage IS NOT NULL 
    AND fo.return_percentage != 0
ORDER BY 
    fo.return_percentage DESC, 
    fo.total_sales DESC;
