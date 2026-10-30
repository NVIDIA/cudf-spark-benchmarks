WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderLineDetails AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM 
        lineitem li
    JOIN 
        RankedOrders ro ON li.l_orderkey = ro.o_orderkey
    WHERE 
        li.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        li.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.c_name,
    ro.o_orderstatus,
    ro.o_totalprice,
    OLD.revenue,
    NS.n_name AS supplier_nation
FROM 
    RankedOrders ro
JOIN 
    OrderLineDetails OLD ON ro.o_orderkey = OLD.l_orderkey
JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps_suppkey FROM TopSuppliers)
JOIN 
    nation NS ON NS.n_nationkey = s.s_nationkey
WHERE 
    ro.price_rank <= 10
ORDER BY 
    ro.o_totalprice DESC;
