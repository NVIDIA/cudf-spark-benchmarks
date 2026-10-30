
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    WHERE 
        rs.rn <= 5
),
AvgPrices AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
QualifiedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN ap.avg_supplycost IS NULL THEN 'N/A' 
            ELSE CAST(ap.avg_supplycost AS STRING)
        END AS avg_supplycost
    FROM 
        part p
    LEFT JOIN 
        AvgPrices ap ON p.p_partkey = ap.ps_partkey
)
SELECT 
    cp.c_name,
    cp.c_acctbal,
    tp.s_name AS top_supplier,
    qp.p_name,
    qp.p_retailprice,
    qp.avg_supplycost
FROM 
    customer cp
JOIN 
    orders o ON cp.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    QualifiedParts qp ON l.l_partkey = qp.p_partkey
LEFT JOIN 
    TopSuppliers tp ON qp.p_partkey = tp.s_suppkey
WHERE 
    o.o_orderstatus = 'O'
    AND (qp.p_retailprice > 100 OR qp.avg_supplycost = 'N/A')
ORDER BY 
    cp.c_acctbal DESC, qp.p_retailprice ASC
LIMIT 100;
