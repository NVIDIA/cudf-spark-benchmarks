
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
),
TopSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        part p ON rs.rank = 1 AND rs.p_partkey = p.p_partkey
),
OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ts.p_partkey,
    ts.p_name,
    ts.s_name,
    ts.s_acctbal,
    os.total_sales,
    os.unique_customers,
    COALESCE(os.total_sales, 0) AS verified_sales
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrdersSummary os ON ts.p_partkey = os.o_orderkey
WHERE 
    ts.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY 
    ts.p_partkey, os.total_sales DESC;
