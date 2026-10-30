WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn,
        COUNT(*) OVER (PARTITION BY s.s_nationkey) AS total_suppliers
    FROM 
        supplier s
),
SupplierPerformance AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
        RANK() OVER (ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS sales_rank
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        lineitem l ON rs.s_suppkey = l.l_suppkey
    GROUP BY 
        rs.s_suppkey, rs.s_name, rs.s_acctbal
),
CustomerSegment AS (
    SELECT 
        c.c_mktsegment,
        SUM(o.o_totalprice) AS mkt_segment_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    p.p_name,
    ps.ps_availqty,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    sp.total_sales,
    cs.mkt_segment_total,
    CASE 
        WHEN sp.total_sales > 1.2 * (SELECT AVG(total_sales) FROM SupplierPerformance) 
            THEN 'Above Average'
        WHEN sp.total_sales < 0.8 * (SELECT AVG(total_sales) FROM SupplierPerformance) 
            THEN 'Below Average'
        ELSE 'Average'
    END AS performance_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rn = 1 
LEFT JOIN 
    SupplierPerformance sp ON rs.s_suppkey = sp.s_suppkey
LEFT JOIN 
    CustomerSegment cs ON cs.mkt_segment_total > 10000 
WHERE 
    ps.ps_availqty IS NOT NULL
    AND (p.p_retailprice * ps.ps_availqty) > (SELECT AVG(p_retailprice * ps.ps_availqty) FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey)
ORDER BY 
    performance_category, total_sales DESC
LIMIT 50;