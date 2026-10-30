
WITH SupplyCosts AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(od.total_revenue), 0) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT nc.n_nationkey) AS nation_count,
    SUM(sc.total_supply_cost) AS total_supply_cost,
    SUM(rc.total_revenue) AS total_revenue,
    AVG(rc.total_revenue) AS avg_revenue_per_customer
FROM 
    region r
JOIN 
    nation nc ON r.r_regionkey = nc.n_regionkey
LEFT JOIN 
    supplier s ON nc.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplyCosts sc ON s.s_suppkey = sc.p_partkey
LEFT JOIN 
    RankedCustomers rc ON s.s_nationkey = rc.c_custkey
WHERE 
    r.r_name IS NOT NULL AND
    (rc.total_revenue > 0 OR rc.total_revenue IS NULL)
GROUP BY 
    r.r_name
HAVING 
    SUM(sc.total_supply_cost) > 0
ORDER BY 
    avg_revenue_per_customer DESC;
