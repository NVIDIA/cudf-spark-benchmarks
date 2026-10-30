
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 5
),
PartStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    t.c_name,
    t.nation_name,
    p.total_avail_qty,
    p.avg_supply_cost
FROM 
    TopOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN 
    PartStats p ON l.l_partkey = p.ps_partkey
WHERE 
    t.o_totalprice > (SELECT AVG(o.o_totalprice) FROM orders o)
ORDER BY 
    t.o_orderdate DESC, t.o_totalprice DESC
LIMIT 100;
