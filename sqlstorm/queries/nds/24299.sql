
WITH customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS total_dependencies,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_dependencies,
        COALESCE(cd.cd_dep_college_count, 0) AS college_dependencies,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL 
                THEN 'UNKNOWN' 
            WHEN cd.cd_purchase_estimate < 1000 
                THEN 'LOW' 
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 
                THEN 'MEDIUM' 
            ELSE 'HIGH' 
        END AS purchase_segment
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
returns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
sales_summary AS (
    SELECT 
        i.i_item_sk,
        COALESCE(s.total_quantity_sold, 0) AS quantity_sold,
        COALESCE(r.total_returns, 0) AS returns_count,
        (COALESCE(s.total_sales_amount, 0) - COALESCE(r.total_returned_amount, 0)) AS net_sales
    FROM 
        item i
    LEFT JOIN 
        item_sales s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        returns r ON i.i_item_sk = r.sr_item_sk
)
SELECT 
    cm.c_first_name,
    cm.c_last_name,
    cm.cd_gender,
    cm.purchase_segment,
    ss.quantity_sold,
    ss.returns_count,
    ss.net_sales,
    ROW_NUMBER() OVER (PARTITION BY cm.purchase_segment ORDER BY ss.net_sales DESC) AS rank_within_segment
FROM 
    customer_metrics cm
JOIN 
    sales_summary ss ON cm.c_customer_sk = ss.i_item_sk
WHERE 
    (cm.cd_gender = 'F' AND ss.net_sales > 100) OR 
    (cm.cd_gender = 'M' AND ss.net_sales > 250)
ORDER BY 
    cm.purchase_segment, ss.net_sales DESC;
