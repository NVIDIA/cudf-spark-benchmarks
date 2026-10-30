WITH detailed_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(o.o_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_sales
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, s.s_name, n.n_name
)
SELECT 
    d.p_partkey,
    d.p_name,
    CONCAT('Brand: ', d.p_brand, ' | Supplier: ', d.supplier_name, ' | Nation: ', d.nation_name) AS composite_info,
    d.total_quantity,
    d.order_count,
    ROUND(d.avg_sales, 2) AS average_sales,
    CASE 
        WHEN d.total_quantity > 1000 THEN 'High Demand'
        WHEN d.total_quantity BETWEEN 500 AND 1000 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM 
    detailed_info d
WHERE 
    d.avg_sales > 100
ORDER BY 
    d.total_quantity DESC, d.avg_sales DESC;
