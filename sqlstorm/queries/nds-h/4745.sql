WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    p.p_name,
    r.r_name,
    ns.total_orders,
    ns.total_spent,
    COALESCE(sc.total_supply_cost, 0) AS total_supply_cost,
    ns.total_spent - COALESCE(sc.total_supply_cost, 0) AS profit
FROM 
    part p
JOIN 
    supplier s ON p.p_partkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierCost sc ON p.p_partkey = sc.ps_partkey
JOIN 
    CustomerSummary ns ON s.s_suppkey = ns.c_custkey
WHERE 
    p.p_retailprice > 100.00
    AND r.r_name LIKE 'Europe%'
ORDER BY 
    profit DESC
LIMIT 10
OFFSET 5;