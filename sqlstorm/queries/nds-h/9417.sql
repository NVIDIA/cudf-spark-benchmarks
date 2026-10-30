WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), OrderTotals AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
), CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    rs.s_name,
    rs.s_acctbal,
    ot.total_price,
    coc.order_count
FROM 
    RankedSuppliers rs
JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    OrderTotals ot ON ps.ps_suppkey = ot.o_custkey
JOIN 
    CustomerOrderCounts coc ON ot.o_custkey = coc.c_custkey
WHERE 
    rs.rn <= 5 AND 
    p.p_brand = 'Brand#23' AND 
    ot.total_price > 1000
ORDER BY 
    rs.s_acctbal DESC, ot.total_price DESC;
