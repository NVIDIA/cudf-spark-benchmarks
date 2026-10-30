
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.c_name,
        ro.o_orderdate,
        ro.o_totalprice
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availability,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
)
SELECT 
    o.o_orderkey,
    o.c_name,
    o.o_orderdate,
    o.o_totalprice,
    sl.p_name,
    sl.s_name,
    sl.total_availability,
    sl.total_supplycost,
    SUM(oli.l_extendedprice * (1 - oli.l_discount)) AS revenue
FROM 
    HighValueOrders o
JOIN 
    OrderLineItems oli ON o.o_orderkey = oli.l_orderkey
JOIN 
    SupplierDetails sl ON oli.l_partkey = sl.ps_partkey
GROUP BY 
    o.o_orderkey, o.c_name, o.o_orderdate, o.o_totalprice, sl.p_name, sl.s_name, sl.total_availability, sl.total_supplycost
ORDER BY 
    o.o_orderdate DESC, revenue DESC
LIMIT 100;
