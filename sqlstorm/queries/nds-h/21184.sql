
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank,
        p.p_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        p.p_partkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, p.p_partkey
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
FinalResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(r.revenue, 0) AS total_revenue,
        CASE 
            WHEN s.s_suppkey IS NOT NULL AND s.rank = 1 THEN 'Top Supplier'
            ELSE 'Other Supplier'
        END AS supplier_status
    FROM 
        part p
    LEFT JOIN 
        (SELECT p_partkey, SUM(revenue) AS revenue 
         FROM OrderDetails 
         GROUP BY p_partkey) r ON p.p_partkey = r.p_partkey
    LEFT JOIN 
        RankedSuppliers s ON p.p_partkey = s.p_partkey
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.total_revenue,
    f.supplier_status,
    sp.supplier_count
FROM 
    FinalResults f
JOIN 
    SupplierPartCounts sp ON f.p_partkey = sp.ps_partkey
WHERE 
    f.total_revenue > (SELECT AVG(total_revenue) FROM FinalResults WHERE total_revenue IS NOT NULL)
ORDER BY 
    f.total_revenue DESC, f.supplier_status ASC
LIMIT 10;
