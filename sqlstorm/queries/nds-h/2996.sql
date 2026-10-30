
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linestatus) AS distinct_line_statuses
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    rs.s_name AS supplier_name,
    psc.supplier_count,
    od.total_revenue,
    od.distinct_line_statuses,
    COALESCE(rs.s_acctbal, 0) AS supplier_account_balance,
    CASE 
        WHEN od.total_revenue > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    part p
LEFT JOIN 
    PartSupplierCount psc ON p.p_partkey = psc.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON psc.supplier_count > 0 AND rs.rank = 1
LEFT JOIN 
    OrderDetails od ON rs.s_suppkey = od.o_orderkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    p.p_partkey;
