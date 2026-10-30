WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 100
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(cp.total_spent), 0) AS total_spent_by_region,
    AVG(sp.avg_supply_cost) AS avg_supply_cost_per_part,
    MAX(o.o_orderdate) AS latest_order_date,
    COUNT(DISTINCT o.o_orderkey) AS distinct_orders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customerOrders cp ON n.n_nationkey = cp.c_custkey
LEFT JOIN 
    lineitem l ON cp.c_custkey = l.l_suppkey
LEFT JOIN 
    SupplierParts sp ON l.l_partkey = sp.p_partkey
LEFT JOIN 
    RankedOrders o ON cp.c_custkey = o.o_orderkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_spent_by_region DESC
LIMIT 10;