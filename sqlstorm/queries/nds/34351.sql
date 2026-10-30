
WITH  sales_hierarchy AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        cd.cd_gender,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
), max_sales AS (
    SELECT 
        sh.ws_order_number, 
        SUM(sh.ws_sales_price * sh.ws_quantity) AS total_sales
    FROM 
        sales_hierarchy sh
    GROUP BY 
        sh.ws_order_number
), product_sales AS (
    SELECT 
        cs.cs_order_number,
        i.i_product_name,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY 
        cs.cs_order_number, i.i_product_name
)
SELECT 
    ws.ws_order_number,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_web_sales,
    MAX(p.total_profit) AS max_product_profit,
    STRING_AGG(DISTINCT p.i_product_name) AS best_selling_products,
    CASE 
        WHEN MAX(s.total_sales) > 10000 THEN 'High Value'
        WHEN MAX(s.total_sales) BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS sales_category
FROM 
    web_sales ws
LEFT JOIN 
    max_sales s ON ws.ws_order_number = s.ws_order_number
LEFT JOIN 
    product_sales p ON ws.ws_order_number = p.cs_order_number
WHERE 
    ws.ws_sales_price IS NOT NULL
    AND ws.ws_quantity > 0
GROUP BY 
    ws.ws_order_number
ORDER BY 
    total_web_sales DESC;
