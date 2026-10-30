
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_value_items AS (
    SELECT 
        i_item_sk, 
        i_item_desc,
        i_current_price
    FROM 
        item
    WHERE 
        i_current_price > 100 
        AND i_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE sales_rank <= 5)
),
customer_info AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer
    LEFT JOIN 
        customer_demographics ON c_customer_sk = cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender, cd_marital_status
),
sales_analysis AS (
    SELECT 
        hi.i_item_sk,
        hi.i_item_desc,
        hi.i_current_price,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.total_customers,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_value
    FROM 
        high_value_items hi
    JOIN 
        web_sales ws ON hi.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        hi.i_item_sk, hi.i_item_desc, hi.i_current_price, ci.cd_gender, ci.cd_marital_status, ci.total_customers
)
SELECT 
    s.i_item_sk,
    s.i_item_desc,
    s.i_current_price,
    COALESCE(s.total_quantity_sold, 0) AS quantity_sold,
    COALESCE(s.total_sales_value, 0.00) AS sales_value,
    CASE 
        WHEN s.total_sales_value > 0 THEN 'High D'
        ELSE 'No Sales'
    END AS sales_status
FROM 
    sales_analysis s
WHERE 
    s.total_quantity_sold IS NOT NULL
    AND (s.total_sales_value IS NOT NULL OR s.total_sales_value IS NULL)
ORDER BY 
    s.total_sales_value DESC,
    s.total_quantity_sold ASC
LIMIT 10;
