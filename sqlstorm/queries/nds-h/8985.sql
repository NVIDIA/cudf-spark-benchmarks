
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderpriority, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND 
        o.o_orderdate < DATE '1995-12-31'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
JoinResults AS (
    SELECT 
        r.r_name, 
        n.n_name, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        o.o_orderkey
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND 
        o.o_orderdate < DATE '1995-12-31' AND 
        o.o_orderstatus = 'F'
    GROUP BY 
        r.r_name, n.n_name, c.c_name, o.o_orderkey
)
SELECT 
    J.r_name, 
    J.n_name, 
    J.c_name, 
    J.revenue,
    R.rn
FROM 
    JoinResults J
JOIN 
    RankedOrders R ON R.o_orderkey = J.o_orderkey
ORDER BY 
    J.revenue DESC, 
    R.rn ASC;
