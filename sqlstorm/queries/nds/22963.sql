
WITH  sales_trend AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        CAST(d_date AS DATE) AS sold_date,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_date BETWEEN '2022-01-01' AND '2023-01-01'
), 
customer_segment AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_marital_status = 'M' 
        AND cd_purchase_estimate > 500
    GROUP BY 
        cd_gender
), 
item_performance AS (
    SELECT 
        i_item_sk,
        SUM(ws_sales_price - ws_ext_discount_amt) AS total_revenue,
        AVG(ws_quantity) AS avg_quantity_sold,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_item_sk
), 
return_analysis AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)

SELECT 
    it.i_item_id, 
    it.i_item_desc,
    COALESCE(sp.total_revenue, 0) AS total_sales,
    COALESCE(sp.avg_quantity_sold, 0) AS avg_quantity,
    COALESCE(ra.total_returned, 0) AS total_returns,
    cs.customer_count,
    CASE 
        WHEN COALESCE(sp.total_revenue, 0) > 10000 THEN 'High Revenue'
        WHEN COALESCE(sp.total_revenue, 0) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_segment
FROM 
    item_performance sp
LEFT JOIN 
    item it ON sp.i_item_sk = it.i_item_sk
LEFT JOIN 
    return_analysis ra ON ra.sr_item_sk = sp.i_item_sk
LEFT JOIN 
    customer_segment cs ON cs.cd_gender = (SELECT MAX(cd_gender) FROM customer_demographics)
WHERE 
    (sp.order_count > 10 OR ra.return_count IS NULL)
ORDER BY 
    total_sales DESC, avg_quantity DESC 
LIMIT 100;
