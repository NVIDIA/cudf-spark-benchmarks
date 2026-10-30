WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
ExtendedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    ro.o_totalprice,
    el.revenue,
    ts.total_cost,
    ro.order_rank
FROM 
    RankedOrders ro
LEFT JOIN 
    ExtendedLineItems el ON ro.o_orderkey = el.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON el.revenue > ts.total_cost
WHERE 
    ro.order_rank <= 10
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;