
WITH RankedSales AS (
    SELECT 
        l.l_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON p.p_partkey = l.l_partkey
    GROUP BY 
        l.l_partkey, p.p_name
),  
SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT o.o_orderkey) AS orders_supplied,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supplied_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey 
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_regionkey, 
    r.r_name,
    COALESCE(SUM(ss.total_supplied_cost), 0) AS total_supplier_cost,
    COUNT(DISTINCT ss.s_suppkey) AS distinct_suppliers,
    MAX(rs.total_sales) AS max_part_sales,
    COUNT(DISTINCT rs.sales_rank) AS unique_part_sales_rank
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    SupplierSales ss ON ss.s_suppkey = c.c_custkey
LEFT JOIN 
    RankedSales rs ON ss.s_suppkey = rs.l_partkey
WHERE 
    r.r_name LIKE 'A%' 
    AND ss.orders_supplied > 5
GROUP BY 
    r.r_regionkey, r.r_name
ORDER BY 
    r.r_regionkey;
