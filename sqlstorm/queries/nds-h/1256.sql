
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    rs.s_name,
    rs.s_acctbal,
    hvo.o_orderkey,
    hvo.o_orderdate,
    tp.p_name,
    tp.total_quantity,
    CASE
        WHEN hvo.total_value > 100000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS order_type
FROM 
    RankedSuppliers rs
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_suppkey = rs.s_suppkey
    )
LEFT JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    TopParts tp ON ps.ps_partkey = tp.p_partkey 
WHERE 
    rs.rnk <= 5
ORDER BY 
    rs.s_acctbal DESC, hvo.o_orderdate DESC;
