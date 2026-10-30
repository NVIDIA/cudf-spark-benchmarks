
WITH RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPart AS (
    SELECT 
        ps.ps_suppkey,
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_avail
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey, p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    pt.p_partkey,
    pt.total_avail,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(rs.total_sales, 0) = 0 THEN 'No Sales' 
        ELSE 'Sales Exist' 
    END AS sales_status
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPart pt ON s.s_suppkey = pt.ps_suppkey
LEFT JOIN 
    RankedSales rs ON pt.p_partkey = rs.c_custkey 
WHERE 
    (pt.total_avail IS NOT NULL AND pt.total_avail > 0)
    OR (rs.total_sales IS NULL OR rs.total_sales < 1000)
ORDER BY 
    region_name, nation_name, supplier_name;
