
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
RankedSales AS (
    SELECT 
        c_customer_id,
        total_sales,
        order_count,
        average_profit,
        unique_web_pages,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.order_count,
    r.average_profit,
    r.unique_web_pages,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 100
ORDER BY 
    r.sales_rank;
