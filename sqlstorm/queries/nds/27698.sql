
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS email_domain
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
WebPageStats AS (
    SELECT 
        wp.wp_url,
        COUNT(wp.wp_web_page_sk) AS access_count,
        SUM(wp.wp_char_count) AS total_chars,
        SUM(wp.wp_link_count) AS total_links
    FROM web_page wp
    GROUP BY wp.wp_url
),
SalesStats AS (
    SELECT 
        'Web Sales' AS sales_type,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(ws.ws_item_sk) AS total_items_sold
    FROM web_sales ws
    UNION ALL
    SELECT 
        'Store Sales' AS sales_type,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
        COUNT(ss.ss_item_sk) AS total_items_sold
    FROM store_sales ss
)
SELECT 
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    w.access_count,
    w.total_chars,
    w.total_links,
    s.sales_type,
    s.total_sales,
    s.total_orders,
    s.total_items_sold
FROM CustomerDetails cd
JOIN WebPageStats w ON cd.email_domain = w.wp_url
JOIN SalesStats s ON s.total_orders > 0
ORDER BY cd.ca_city, s.total_sales DESC;
