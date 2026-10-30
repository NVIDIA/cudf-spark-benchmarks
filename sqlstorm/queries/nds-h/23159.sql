WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
SalesData AS (
    SELECT 
        o.o_orderkey,
        l.l_quantity * l.l_extendedprice * (1 - l.l_discount) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
),
FilteredRegions AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey
    HAVING 
        COUNT(n.n_nationkey) > 1
),
FinalResults AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        SUM(d.revenue) AS total_revenue,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        FilteredRegions fr
    JOIN 
        RankedSuppliers s ON fr.nation_count = s.rank
    JOIN 
        SalesData d ON s.s_suppkey = d.o_orderkey
    JOIN 
        region r ON r.r_regionkey = fr.r_regionkey
    WHERE 
        s.rank = 1 OR s.s_acctbal IS NULL
    GROUP BY 
        r.r_name, s.s_name
)
SELECT 
    f.region_name,
    f.supplier_name,
    COALESCE(f.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN f.supplier_count IS NULL THEN 'Supplier count not available'
        ELSE CAST(f.supplier_count AS STRING)
    END AS supplier_count_details
FROM 
    FinalResults f
UNION 
SELECT 
    r.r_name,
    NULL AS supplier_name,
    0 AS total_revenue,
    'No suppliers' AS supplier_count_details
FROM 
    region r
WHERE 
    r.r_regionkey NOT IN (SELECT DISTINCT fr.r_regionkey FROM FilteredRegions fr);
