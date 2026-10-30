WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenues AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate,
        r.total_revenue,
        c.c_name,
        s.s_name,
        p.p_name,
        p.p_mfgr
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        r.order_rank <= 10
)
SELECT 
    tr.o_orderkey,
    tr.o_orderdate,
    tr.total_revenue,
    tr.c_name AS customer_name,
    tr.s_name AS supplier_name,
    tr.p_name AS part_name,
    tr.p_mfgr AS manufacturer_name
FROM 
    TopRevenues tr
ORDER BY 
    tr.total_revenue DESC;