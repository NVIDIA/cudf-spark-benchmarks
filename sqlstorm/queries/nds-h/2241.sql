
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk,
        s.s_nationkey
    FROM 
        supplier s
),
HighBalanceSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rnk <= 3
),
PartSupplierCounts AS (
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
    p.p_retailprice,
    COALESCE(hs.supplier_count, 0) AS high_balance_supplier_count,
    CASE 
        WHEN COALESCE(hs.supplier_count, 0) > 0 THEN 'Available'
        ELSE 'Not Available'
    END AS supplier_availability,
    SUM(CASE 
        WHEN l.l_discount = 0.0 THEN l.l_extendedprice
        ELSE l.l_extendedprice * (1 - l.l_discount) 
        END) AS total_revenue
FROM 
    part p
LEFT JOIN 
    PartSupplierCounts hs ON p.p_partkey = hs.ps_partkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    HighBalanceSuppliers hbs ON hbs.s_suppkey = l.l_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, hs.supplier_count
HAVING 
    SUM(CASE 
        WHEN l.l_discount = 0.0 THEN l.l_extendedprice
        ELSE l.l_extendedprice * (1 - l.l_discount) 
    END) > 10000
ORDER BY 
    p.p_retailprice DESC, total_revenue DESC;
