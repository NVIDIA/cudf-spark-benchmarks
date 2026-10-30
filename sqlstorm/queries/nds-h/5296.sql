WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) as rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TotalRevenue AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        n.n_name AS nation_name
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        p.p_partkey, p.p_name, n.n_name
),
FinalSelection AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.c_name,
        r.c_mktsegment,
        tr.p_partkey,
        tr.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        TotalRevenue tr ON r.o_orderkey = tr.p_partkey
    WHERE 
        r.rn <= 5
)
SELECT 
    fs.o_orderkey,
    fs.o_orderdate,
    fs.c_name,
    fs.c_mktsegment,
    fs.p_partkey,
    fs.total_revenue
FROM 
    FinalSelection fs
ORDER BY 
    fs.total_revenue DESC
LIMIT 10;
