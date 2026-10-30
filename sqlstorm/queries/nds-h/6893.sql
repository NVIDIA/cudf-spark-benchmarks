WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_nationkey
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
SupplierStatistics AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.c_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    ss.total_supply_cost,
    ss.avg_supply_cost
FROM 
    HighValueOrders hvo
JOIN 
    nation n ON hvo.c_nationkey = n.n_nationkey
JOIN 
    lineitem l ON hvo.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    SupplierStatistics ss ON l.l_partkey = ss.ps_partkey
WHERE 
    hvo.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
ORDER BY 
    hvo.o_totalprice DESC, hvo.o_orderdate ASC;