WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name
),
TopRevOrders AS (
    SELECT 
        o.o_orderkey,
        o.c_name,
        o.total_revenue
    FROM 
        RankedOrders o
    WHERE 
        o.order_rank <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
HighCostParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        sp.total_cost
    FROM 
        part p
    JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    WHERE 
        sp.total_cost > 1000
)
SELECT 
    tro.o_orderkey,
    tro.c_name,
    hcp.p_name,
    hcp.total_cost
FROM 
    TopRevOrders tro
JOIN 
    lineitem li ON tro.o_orderkey = li.l_orderkey
JOIN 
    HighCostParts hcp ON li.l_partkey = hcp.p_partkey
ORDER BY 
    tro.total_revenue DESC, hcp.total_cost DESC;