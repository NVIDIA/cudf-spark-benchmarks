WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.nation_name,
        r.s_suppkey,
        r.s_name,
        r.s_acctbal
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank <= 5
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopParts AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        ps.total_available,
        ps.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY ps.total_available DESC) AS rank
    FROM 
        PartStatistics ps
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    tp.p_name,
    ts.s_name,
    ts.nation_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopParts tp ON l.l_partkey = tp.p_partkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderstatus = 'F'
AND 
    tp.rank <= 10
ORDER BY 
    tp.total_available DESC, 
    o.o_orderdate DESC;
