WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS Rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1996-12-31'
),
TopSegments AS (
    SELECT 
        m.mktsegment,
        SUM(o.o_totalprice) AS TotalRevenue
    FROM 
        RankedOrders o
    JOIN 
        (SELECT DISTINCT c_mktsegment AS mktsegment FROM customer) m ON o.c_mktsegment = m.mktsegment
    WHERE 
        o.Rank <= 10
    GROUP BY 
        m.mktsegment
)
SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    ts.mktsegment,
    ts.TotalRevenue
FROM 
    TopSegments ts
JOIN 
    supplier s ON s.s_nationkey = 
        (SELECT n.n_nationkey 
         FROM nation n 
         JOIN region r ON n.n_regionkey = r.r_regionkey
         WHERE r.r_name = 'Asia' LIMIT 1)
JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = o.o_custkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    l.l_shipdate >= DATE '1996-01-01'
    AND l.l_shipdate < DATE '1996-12-31'
ORDER BY 
    ts.TotalRevenue DESC;