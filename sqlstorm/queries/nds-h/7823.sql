WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    r.r_name,
    tc.o_orderkey,
    tc.o_totalprice,
    sc.total_supply_cost
FROM 
    TopOrders tc
JOIN 
    lineitem li ON tc.o_orderkey = li.l_orderkey
JOIN 
    part p ON li.l_partkey = p.p_partkey
JOIN 
    supplier s ON li.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierCost sc ON p.p_partkey = sc.ps_partkey AND s.s_suppkey = sc.ps_suppkey
WHERE 
    sc.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierCost);