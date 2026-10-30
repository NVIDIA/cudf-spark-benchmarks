
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 0
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' 
        AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    n.n_name AS nation_name,
    r.p_name,
    COALESCE(r.total_available, 0) AS available_quantity,
    od.total_price,
    CASE 
        WHEN od.part_count > 5 THEN 'Large Order'
        WHEN od.part_count BETWEEN 3 AND 5 THEN 'Medium Order'
        ELSE 'Small Order'
    END AS order_size,
    COUNT(DISTINCT rl.s_suppkey) AS supplier_count
FROM 
    AvailableParts r
LEFT JOIN 
    lineitem l ON r.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    RankedSuppliers rl ON rl.s_nationkey = n.n_nationkey AND rl.supplier_rank = 1
JOIN 
    OrderDetails od ON o.o_orderkey = od.o_orderkey
WHERE 
    (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
    AND (l.l_shipmode = 'Air' OR l.l_shipmode = 'Ground')
    AND r.total_available > (SELECT AVG(total_available) FROM AvailableParts)
GROUP BY 
    n.n_name, r.p_name, r.total_available, od.total_price, od.part_count
ORDER BY 
    n.n_name, available_quantity DESC, total_price DESC;
