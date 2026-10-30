
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(cp.total_spent) AS average_spent,
    MAX(cp.total_orders) AS max_orders,
    COALESCE(SUM(sc.total_supplycost), 0) AS total_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierCosts sc ON s.s_suppkey = sc.ps_partkey
LEFT JOIN 
    CustomerPurchases cp ON s.s_suppkey = cp.c_custkey
LEFT JOIN 
    customer c ON c.c_custkey = cp.c_custkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    AVG(cp.total_spent) > 1000
ORDER BY 
    r.r_name
LIMIT 10 OFFSET 0;
