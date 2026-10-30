WITH StringAggregates AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_brand, ' (', p.p_container, ')') AS part_description,
        SUM(l.l_extendedprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_container
),
FilteredParts AS (
    SELECT 
        part_description,
        total_sales,
        order_count,
        last_ship_date
    FROM 
        StringAggregates
    WHERE 
        total_sales > 10000
)
SELECT 
    part_description,
    total_sales,
    order_count,
    last_ship_date,
    SUBSTRING(part_description, 1, 30) AS short_description
FROM 
    FilteredParts
ORDER BY 
    total_sales DESC
LIMIT 10;
