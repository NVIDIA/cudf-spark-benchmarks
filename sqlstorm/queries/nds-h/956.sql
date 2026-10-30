WITH RegionOrderSummary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        AVG(o.o_totalprice) AS avg_order_value,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
        AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        r.r_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 10
)

SELECT 
    r.r_name,
    ros.total_orders,
    ros.total_sales,
    ros.avg_order_value, 
    CASE 
        WHEN ros.rank_sales <= 3 THEN 'Top Region'
        WHEN ros.rank_sales <= 6 THEN 'Mid Region'
        ELSE 'Other Region'
    END AS sales_category
FROM 
    region r
JOIN 
    RegionOrderSummary ros ON r.r_name = ros.r_name
ORDER BY 
    ros.total_sales DESC;