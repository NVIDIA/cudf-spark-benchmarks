
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        (SELECT 
            COUNT(DISTINCT ws_bill_customer_sk) 
         FROM 
            web_sales 
         WHERE 
            ws_item_sk = i.i_item_sk) AS unique_customers,
        (SELECT 
            COUNT(DISTINCT cs_order_number) 
         FROM 
            catalog_sales 
         WHERE 
            cs_item_sk = i.i_item_sk) AS catalog_sales_orders
    FROM 
        item i
),
combine_sales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        item.i_current_price,
        item.unique_customers,
        item.catalog_sales_orders,
        ranked.total_sales,
        ranked.sales_rank
    FROM 
        item_details item
    LEFT JOIN 
        ranked_sales ranked ON item.i_item_sk = ranked.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(ca.ca_city, 'Unknown') AS address_city,
    COALESCE(cal.cc_name, 'Not Available') AS call_center,
    cs.total_sales,
    cs.sales_rank,
    CASE 
        WHEN cs.total_sales IS NULL AND cs.sales_rank IS NULL THEN 'No Sales Data'
        WHEN cs.total_sales IS NOT NULL THEN CONCAT('Total Sales: ', cs.total_sales)
        ELSE 'Sales Data Available but Rank Missing'
    END AS sales_info
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    combine_sales cs ON cs.unique_customers = (SELECT 
                                                  MAX(unique_customers) 
                                               FROM 
                                                  combine_sales)
LEFT JOIN 
    call_center cal ON cal.cc_call_center_sk = (SELECT 
                                                    MIN(cc_call_center_sk) 
                                                 FROM 
                                                    call_center)
WHERE 
    (c.c_first_name LIKE 'J%' OR c.c_last_name LIKE 'J%')
    AND (c.c_birth_year IS NOT NULL OR c.c_preferred_cust_flag = 'Y')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    cal.cc_name, 
    cs.total_sales, 
    cs.sales_rank
ORDER BY 
    cs.sales_rank NULLS LAST, 
    c.c_last_name
LIMIT 100;
