WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
LatestOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.order_total,
        c.c_name,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    LEFT JOIN 
        partsupp ps ON ps.ps_partkey = (
            SELECT 
                p.p_partkey 
            FROM 
                part p 
            WHERE 
                p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
                AND p.p_size BETWEEN 0 AND 50
            LIMIT 1
        )
    WHERE 
        ro.rn = 1
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.order_total, c.c_name
)
SELECT 
    lo.o_orderkey,
    lo.o_orderdate,
    lo.order_total,
    lo.c_name,
    CASE 
        WHEN lo.total_supply_cost IS NULL THEN 'No cost data'
        ELSE CAST(lo.total_supply_cost AS STRING)
    END AS total_supply_cost_label,
    COUNT(DISTINCT s.s_suppkey) FILTER (WHERE s.s_acctbal > 100) AS high_value_suppliers_count
FROM 
    LatestOrders lo
LEFT JOIN 
    supplier s ON s.s_nationkey = (
        SELECT 
            n.n_nationkey 
        FROM 
            nation n 
        JOIN 
            region r ON n.n_regionkey = r.r_regionkey 
        WHERE 
            r.r_name = 'EUROPE' 
        LIMIT 1
    )
GROUP BY 
    lo.o_orderkey, lo.o_orderdate, lo.order_total, lo.c_name, lo.total_supply_cost
HAVING 
    lo.order_total > (SELECT AVG(order_total) FROM LatestOrders)
ORDER BY 
    lo.order_total DESC
LIMIT 10;
