WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
DistinctRegions AS (
    SELECT DISTINCT
        r.r_regionkey,
        r.r_name
    FROM 
        region r
    WHERE 
        r.r_comment IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS num_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal)
            FROM customer c2
            WHERE c2.c_mktsegment = c.c_mktsegment
        )
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    SUM(sp.total_available) AS total_available_parts,
    SUM(co.total_spent) AS total_spent_by_customers,
    (SELECT COUNT(*) 
     FROM customer c 
     JOIN orders o ON c.c_custkey = o.o_custkey 
     WHERE o.o_orderstatus = 'O') AS total_open_orders
FROM 
    DistinctRegions r
LEFT JOIN 
    SupplierParts sp ON 1 = CASE WHEN r.r_regionkey IS NULL THEN 0 ELSE 1 END
LEFT JOIN 
    CustomerOrders co ON 1 = CASE WHEN r.r_name IS NULL THEN 0 ELSE 1 END
LEFT JOIN 
    RankedOrders ro ON ro.order_rank = 1 AND ro.o_orderkey IS NOT NULL
WHERE 
    r.r_name LIKE '%East%'
    OR EXISTS (SELECT 1 
                FROM nation n 
                WHERE n.n_regionkey = r.r_regionkey 
                AND n.n_comment LIKE '%specific%')
GROUP BY 
    r.r_name
HAVING 
    SUM(sp.total_available) > COALESCE(SUM(co.total_spent), 0)
ORDER BY 
    r.r_name ASC, total_available_parts DESC;
