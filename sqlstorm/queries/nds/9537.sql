
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND ca.ca_state IN ('NY', 'CA', 'TX')
), DiscountAnalysis AS (
    SELECT 
        sd.ca_state,
        sd.cd_gender,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price) AS total_sales,
        SUM(sd.ws_ext_discount_amt) AS total_discount,
        (SUM(sd.ws_sales_price) - SUM(sd.ws_ext_discount_amt)) AS net_revenue
    FROM 
        SalesData sd
    GROUP BY 
        sd.ca_state, sd.cd_gender
), FinalReport AS (
    SELECT 
        da.ca_state,
        da.cd_gender,
        da.total_quantity,
        da.total_sales,
        da.total_discount,
        da.net_revenue,
        RANK() OVER (PARTITION BY da.ca_state ORDER BY da.net_revenue DESC) AS rank_by_revenue
    FROM 
        DiscountAnalysis da
)
SELECT 
    fr.ca_state,
    fr.cd_gender,
    fr.total_quantity,
    fr.total_sales,
    fr.total_discount,
    fr.net_revenue,
    fr.rank_by_revenue
FROM 
    FinalReport fr
WHERE 
    fr.rank_by_revenue <= 5
ORDER BY 
    fr.ca_state, fr.rank_by_revenue;
