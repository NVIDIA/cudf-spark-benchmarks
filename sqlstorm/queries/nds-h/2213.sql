
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(sc.total_supply_cost) AS total_cost
    FROM 
        supplier s
    LEFT JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)

SELECT 
    c.c_name,
    c.total_spent,
    fo.o_orderkey,
    s.s_name,
    s.total_cost,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY fo.o_orderdate DESC) AS recent_order,
    CASE 
        WHEN s.total_cost > c.total_spent THEN 'Higher Cost'
        ELSE 'Lower Cost'
    END AS cost_comparison
FROM 
    CustomerOrders c
JOIN 
    RankedOrders fo ON c.c_custkey = fo.o_custkey
JOIN 
    FilteredSuppliers s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
WHERE 
    fo.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
ORDER BY 
    c.total_spent DESC, fo.o_orderdate DESC;
